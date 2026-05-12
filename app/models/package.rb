class Package < ApplicationRecord
  enum :status, { pending: 0, stored: 1, picked_up: 2, exception: 3 }
  enum :package_type, { normal: 0, large: 1, fragile: 2, valuable: 3 }

  belongs_to :user, optional: true
  belongs_to :stored_by, class_name: "User", optional: true
  belongs_to :picked_up_by, class_name: "User", optional: true
  has_many :package_exceptions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :tracking_number,
            presence: { message: "运单号不能为空" },
            uniqueness: { message: "该运单号已存在" },
            length: { in: 12..18, message: "运单号长度必须在12-18位之间" },
            format: { with: /\A[A-Z0-9]+\z/, message: "运单号只能包含大写字母和数字" }
  validates :pickup_code, presence: { message: "取件码不能为空" }, uniqueness: { message: "该取件码已存在" }, length: { maximum: 20, message: "取件码不能超过20个字符" }, on: :update
  validates :recipient_name,
            presence: { message: "收件人不能为空" },
            length: { in: 2..20, message: "收件人姓名长度必须在2-20个字符之间" },
            format: { with: /\A[\u4e00-\u9fa5a-zA-Z0-9]+\z/, message: "收件人姓名只能包含中文、英文和数字" }
  validates :recipient_phone,
            presence: { message: "手机号不能为空" },
            format: { with: /\A1[3-9]\d{9}\z/, message: "请输入正确的11位手机号" }
  validates :recipient_address, length: { maximum: 200, message: "地址不能超过200个字符" }, allow_blank: true
  validates :courier_company, presence: { message: "请选择快递公司" }
  validates :storage_location, length: { maximum: 100, message: "存放位置不能超过100个字符" }, allow_blank: true
  validates :weight, numericality: { greater_than: 0, message: "重量必须大于0" }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_recipient_phone, ->(phone) { where(recipient_phone: phone) }
  scope :by_tracking_number, ->(number) { where(tracking_number: number) }
  scope :by_pickup_code, ->(code) { where(pickup_code: code) }
  scope :stored_today, -> { where(stored_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :picked_up_today, -> { where(picked_up_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :overdue, -> { where("stored_at < ?", 3.days.ago).where(status: [ :stored, :exception ]) }
  scope :not_deleted, -> { where(deleted_at: nil) }

  before_create :generate_pickup_code, if: -> { pickup_code.blank? }

  def store!(user)
    raise "包裹状态必须是待入库才能入库" unless pending?

    update!(
      status: :stored,
      stored_at: Time.current,
      stored_by: user
    )
    create_notification(:stored)
    # 发送取件通知短信
    Notification.create_and_send_pickup_notification(self)
  end

  def pick_up!(user, pickup_phone = nil)
    raise "包裹状态必须是已入库才能出库" unless stored?
    raise "取件人手机号不能为空" unless pickup_phone.present?
    raise "手机号格式不正确" unless pickup_phone.match?(/\A1[3-9]\d{9}\z/)

    update!(
      status: :picked_up,
      picked_up_at: Time.current,
      picked_up_by: user,
      pickup_phone: pickup_phone
    )
    create_notification(:picked_up)
  end

  def mark_exception!(exception_type, description, user)
    # 只有已入库状态的包裹才能标记异常
    raise "只有已入库状态的包裹才能标记异常" unless stored?

    transaction do
      update!(status: :exception)
      package_exceptions.create!(
        exception_type: exception_type,
        description: description,
        reported_by: user,
        status: :pending,
        exception_time: Time.current
      )
    end
    create_notification(:exception)
  end

  def storage_duration
    return nil unless stored_at
    end_time = picked_up_at || Time.current
    ((end_time - stored_at) / 1.hour).round(2)
  end

  def overdue?
    return false unless stored_at
    stored_at < 3.days.ago && (stored? || exception?)
  end

  def self.search(params)
    packages = not_deleted

    # 关键词搜索（支持运单号/取件码/收件人姓名/手机号多字段模糊匹配）
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      packages = packages.where(
        "tracking_number LIKE ? OR pickup_code LIKE ? OR recipient_name LIKE ? OR recipient_phone LIKE ?",
        keyword, keyword, keyword, keyword
      )
    end

    packages = packages.by_tracking_number(params[:tracking_number]) if params[:tracking_number].present?
    packages = packages.by_recipient_phone(params[:recipient_phone]) if params[:recipient_phone].present?
    packages = packages.by_pickup_code(params[:pickup_code]) if params[:pickup_code].present?
    packages = packages.by_status(params[:status]) if params[:status].present?
    packages = packages.where(courier_company: params[:courier_company]) if params[:courier_company].present?
    packages = packages.where("recipient_name LIKE ?", "%#{params[:recipient_name]}%") if params[:recipient_name].present?
    packages = packages.where("storage_location LIKE ?", "%#{params[:storage_location]}%") if params[:storage_location].present?

    # 时间范围筛选（到达时间）
    if params[:start_date].present? && params[:end_date].present?
      packages = packages.where(stored_at: params[:start_date]..params[:end_date])
    elsif params[:start_date].present?
      packages = packages.where("stored_at >= ?", params[:start_date])
    elsif params[:end_date].present?
      packages = packages.where("stored_at <= ?", params[:end_date])
    end

    packages
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def self.statistics_by_date(start_date, end_date)
    packages = where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    {
      total: packages.count,
      stored: packages.where(status: [ :stored, :picked_up ]).count,
      picked_up: packages.where(status: :picked_up).count,
      exception: packages.where(status: :exception).count,
      pending: packages.where(status: :pending).count,
      by_date: packages.group_by_day(:created_at).count,
      by_status: packages.group(:status).count.transform_keys { |k| Package.statuses.key(k) }
    }
  end

  private

  def generate_pickup_code
    self.pickup_code = "#{Time.current.strftime('%m%d')}#{SecureRandom.random_number(9999).to_s.rjust(4, '0')}"
  end

  def create_notification(type)
    return unless user

    case type
    when :stored
      notifications.create!(
        user: user,
        title: "包裹已入库",
        content: "您的包裹（运单号：#{tracking_number}）已入库，取件码：#{pickup_code}",
        notification_type: :stored
      )
    when :picked_up
      notifications.create!(
        user: user,
        title: "包裹已取件",
        content: "您的包裹（运单号：#{tracking_number}）已成功取件",
        notification_type: :picked_up
      )
    when :exception
      notifications.create!(
        user: user,
        title: "包裹异常提醒",
        content: "您的包裹（运单号：#{tracking_number}）出现异常情况，请联系驿站工作人员",
        notification_type: :exception
      )
    end
  end
end
