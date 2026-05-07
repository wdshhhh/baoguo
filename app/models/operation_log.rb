class OperationLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true, length: { maximum: 50 }
  validates :resource_type, length: { maximum: 50 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  def self.log(action, user: nil, resource: nil, details: nil, request: nil)
    log_entry = new(
      action: action,
      user: user,
      details: details
    )

    if resource
      log_entry.resource_type = resource.class.name
      log_entry.resource_id = resource.id
    end

    if request
      log_entry.ip_address = request.remote_ip
      log_entry.user_agent = request.user_agent
    end

    log_entry.save!
    log_entry
  end

  def self.search(params)
    logs = all
    logs = logs.by_action(params[:action]) if params[:action].present?
    logs = logs.by_user(params[:user_id]) if params[:user_id].present?
    logs = logs.where(resource_type: params[:resource_type]) if params[:resource_type].present?
    logs = logs.by_date_range(params[:start_date], params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    logs
  end

  def resource
    return nil unless resource_type && resource_id
    resource_type.constantize.find_by(id: resource_id)
  end
end
