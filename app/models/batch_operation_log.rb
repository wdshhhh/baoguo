class BatchOperationLog < ApplicationRecord
  # 操作类型
  enum :operation_type, {
    batch_processing: 0,       # 批量标记处理中
    batch_resolve: 1           # 批量解决
  }

  # 操作状态
  enum :status, {
    pending: 0,                # 待执行
    processing: 1,             # 处理中
    completed: 2,              # 完成
    partial_failed: 3          # 部分失败
  }

  belongs_to :user
  has_many :exception_logs, dependent: :nullify

  validates :operation_type, presence: true
  validates :total_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :generate_operation_id

  def generate_operation_id
    return if operation_id.present?
    self.operation_id = "BOP-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.uuid.split('-').first.upcase}"
  end

  def update_progress(current, success_count, fail_count, fail_details = nil)
    update!(
      status: fail_count > 0 && current == total_count ? :partial_failed : :processing,
      current_count: current,
      success_count: success_count,
      fail_count: fail_count,
      fail_details: fail_details
    )
  end

  def complete(success_count, fail_count, fail_details = nil)
    update!(
      status: fail_count > 0 ? :partial_failed : :completed,
      current_count: total_count,
      success_count: success_count,
      fail_count: fail_count,
      fail_details: fail_details,
      completed_at: Time.current
    )
  end
end
