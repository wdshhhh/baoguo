# OCR记录模型
class OcrRecord < ApplicationRecord
  # 状态枚举
  enum :status, {
    pending: 0,      # 待处理
    processing: 1,   # 识别中
    recognized: 2,   # 已识别
    corrected: 3,    # 已修正
    failed: 4       # 失败
  }

  # 关联用户
  belongs_to :user, optional: true

  # 验证
  validates :image_url, presence: true

  # 作用域
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: [:recognized, :corrected]) }
  scope :by_user, ->(user) { where(user: user) }

  # 完整收件地址
  def full_recipient_address
    [recipient_province, recipient_city, recipient_district, recipient_address].compact.join
  end

  # 是否已成功识别
  def successfully_recognized?
    recognized? || corrected?
  end

  # 更新状态
  def update_status(new_status, message = nil)
    update!(
      status: new_status,
      error_message: message
    )
  end

  # 计算置信度（基于字段识别率）
  def calculate_confidence
    fields = [:tracking_number, :recipient_name, :recipient_phone, :recipient_address]
    recognized_count = fields.count { |field| send(field).present? }
    (recognized_count.to_f / fields.size).round(2)
  end
end