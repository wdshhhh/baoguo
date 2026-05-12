class LoginSession < ApplicationRecord
  belongs_to :user

  validates :refresh_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :valid, -> { where("expires_at > ?", Time.current) }

  # 检查会话是否有效
  def active?
    expires_at > Time.current
  end

  # 延长会话有效期
  def extend(expires_in = 7.days)
    update(expires_at: expires_in.from_now)
  end

  # 使会话失效
  def invalidate
    update(expires_at: Time.current)
  end
end
