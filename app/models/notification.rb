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

  private

  def send_push_notification
    # 这里可以集成第三方推送服务，如极光推送、Firebase Cloud Messaging 等
    # 暂时只记录日志
    Rails.logger.info "Push notification sent to user #{user_id}: #{title}"
  end
end
