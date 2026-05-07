class PackageException < ApplicationRecord
  enum :exception_type, { overdue: 0, damaged: 1, wrong_delivery: 2, lost: 3, other: 4 }
  enum :status, { pending: 0, processing: 1, resolved: 2 }

  belongs_to :package
  belongs_to :reported_by, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :exception_type, presence: true
  validates :description, presence: true, length: { maximum: 500 }
  validates :solution, length: { maximum: 500 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(exception_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :pending_exceptions, -> { where(status: [ :pending, :processing ]) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  def resolve!(solution, user)
    update!(
      solution: solution,
      resolved_by: user,
      resolved_at: Time.current,
      status: :resolved
    )
    package.update!(status: :stored) if package.exception?
  end

  def process!(user)
    update!(
      resolved_by: user,
      status: :processing
    )
  end

  def self.statistics_by_type(start_date, end_date)
    where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .group(:exception_type)
      .count
      .transform_keys { |k| PackageException.exception_types.key(k) }
  end

  def self.statistics_by_status(start_date, end_date)
    where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .group(:status)
      .count
      .transform_keys { |k| PackageException.statuses.key(k) }
  end

  def self.search(params = {})
    exceptions = all

    # 搜索关键词
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      exceptions = exceptions.joins(:package).where(
        "packages.tracking_number LIKE ? OR packages.recipient_phone LIKE ? OR packages.pickup_code LIKE ? OR packages.recipient_name LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # 异常类型筛选
    if params[:exception_type].present?
      exceptions = exceptions.where(exception_type: params[:exception_type])
    end

    # 状态筛选
    if params[:status].present?
      exceptions = exceptions.where(status: params[:status])
    end

    # 运单号筛选
    if params[:package_tracking_number].present?
      exceptions = exceptions.joins(:package).where("packages.tracking_number LIKE ?", "%#{params[:package_tracking_number]}%")
    end

    # 手机号筛选
    if params[:recipient_phone].present?
      exceptions = exceptions.joins(:package).where("packages.recipient_phone LIKE ?", "%#{params[:recipient_phone]}%")
    end

    exceptions
  end
end
