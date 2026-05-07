class Package < ApplicationRecord
  enum :status, { pending: 0, stored: 1, picked_up: 2, exception: 3 }
  enum :package_type, { normal: 0, large: 1, fragile: 2, valuable: 3 }

  belongs_to :user, optional: true
  belongs_to :stored_by, class_name: "User", optional: true
  belongs_to :picked_up_by, class_name: "User", optional: true
  has_many :package_exceptions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :tracking_number, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :pickup_code, presence: true, uniqueness: true, length: { maximum: 20 }, on: :update
  validates :recipient_name, presence: true, length: { maximum: 50 }
  validates :recipient_phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号格式不正确" }
  validates :storage_location, length: { maximum: 100 }, allow_blank: true
  validates :weight, numericality: { greater_than: 0 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_recipient_phone, ->(phone) { where(recipient_phone: phone) }
  scope :by_tracking_number, ->(number) { where(tracking_number: number) }
  scope :by_pickup_code, ->(code) { where(pickup_code: code) }
  scope :stored_today, -> { where(stored_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :picked_up_today, -> { where(picked_up_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :overdue, -> { where("stored_at < ?", 3.days.ago).where(status: [ :stored, :exception ]) }

  before_create :generate_pickup_code, if: -> { pickup_code.blank? }

  def store!(user)
    update!(
      status: :stored,
      stored_at: Time.current,
      stored_by: user
    )
    create_notification(:stored)
  end

  def pick_up!(user)
    update!(
      status: :picked_up,
      picked_up_at: Time.current,
      picked_up_by: user
    )
    create_notification(:picked_up)
  end

  def mark_exception!(exception_type, description, user)
    transaction do
      update!(status: :exception)
      package_exceptions.create!(
        exception_type: exception_type,
        description: description,
        reported_by: user,
        status: :pending
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
    packages = all
    packages = packages.by_tracking_number(params[:tracking_number]) if params[:tracking_number].present?
    packages = packages.by_recipient_phone(params[:recipient_phone]) if params[:recipient_phone].present?
    packages = packages.by_pickup_code(params[:pickup_code]) if params[:pickup_code].present?
    packages = packages.by_status(params[:status]) if params[:status].present?
    packages = packages.where("recipient_name LIKE ?", "%#{params[:recipient_name]}%") if params[:recipient_name].present?
    packages = packages.where("storage_location LIKE ?", "%#{params[:storage_location]}%") if params[:storage_location].present?
    packages = packages.where(stored_at: params[:start_date]..params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    packages
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
