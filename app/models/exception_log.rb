class ExceptionLog < ApplicationRecord
  # 处理方式
  enum :handle_method, {
    contact_customer: 0,      # 联系客户
    contact_courier: 1,       # 联系快递公司
    found: 2,                  # 已找回
    compensated: 3,            # 已赔偿
    return_sender: 4,          # 退回寄件方
    other: 5                   # 其他
  }

  belongs_to :package_exception
  belongs_to :handled_by, class_name: "User"
  belongs_to :batch_operation_log, optional: true

  validates :handle_method, presence: true
  validates :result, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_exception, ->(exception_id) { where(package_exception_id: exception_id) }
  scope :by_batch_operation, ->(batch_operation_id) { where(batch_operation_log_id: batch_operation_id) }
end
