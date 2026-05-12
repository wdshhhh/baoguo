class Notification < ApplicationRecord
  enum :notification_type, { stored: 0, picked_up: 1, overdue: 2, system: 3 }
  enum :status, { unread: 0, read: 1 }

  belongs_to :user
  belongs_to :package, optional: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
  scope :unread_notifications, -> { where(status: :unread) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_package, ->(package_id) { where(package_id: package_id) }

  after_create :send_push_notification

  def mark_as_read!
    update!(status: :read, read_at: Time.current)
  end

  def self.unread_count_for_user(user_id)
    where(user_id: user_id, status: :unread).count
  end

  def self.mark_all_as_read_for_user(user_id)
    where(user_id: user_id, status: :unread).update_all(status: :read, read_at: Time.current)
  end

  # 发送取件通知短信（模拟）
  def send_sms_notification
    return unless recipient_phone.present?

    # 模拟发送短信到控制台
    sms_content = <<~SMS
      📦【菜鸟驿站】取件通知
      您的包裹 #{package&.tracking_number} 已入库
      取件码：#{package&.pickup_code}
      请尽快前往驿站取件，感谢您的使用！
    SMS

    # 打印到控制台
    puts "\n" + "="*60
    puts "📱 短信通知发送成功"
    puts "="*60
    puts "收件人：#{recipient_phone}"
    puts "发送时间：#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "="*60
    puts sms_content
    puts "="*60 + "\n"

    # 更新发送状态
    update!(send_status: 'sent', send_at: Time.current)

    # 记录日志
    Rails.logger.info "SMS notification sent to #{recipient_phone} for package #{package&.tracking_number}"
  end

  # 创建并发送取件通知
  def self.create_and_send_pickup_notification(package)
    return unless package.recipient_phone.present? && package.pickup_code.present?

    notification = create!(
      package: package,
      user: package.user,
      title: '包裹已入库',
      content: "您的包裹（运单号：#{package.tracking_number}）已入库，取件码：#{package.pickup_code}",
      notification_type: :stored,
      recipient_phone: package.recipient_phone,
      send_status: 'pending'
    )

    # 发送短信
    notification.send_sms_notification
    notification
  end

  private

  def send_push_notification
    # 这里可以集成第三方推送服务，如极光推送、Firebase Cloud Messaging 等
    # 暂时只记录日志
    Rails.logger.info "Push notification sent to user #{user_id}: #{title}"
  end
end
