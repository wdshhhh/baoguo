class User < ApplicationRecord
  has_secure_password

  enum :role, { customer: 0, staff: 1, admin: 2 }, default: 0
  enum :status, { disabled: 0, enabled: 1 }, default: 1

  has_many :packages, dependent: :nullify
  has_many :stored_packages, class_name: "Package", foreign_key: "stored_by_id", dependent: :nullify
  has_many :picked_up_packages, class_name: "Package", foreign_key: "picked_up_by_id", dependent: :nullify
  has_many :reported_exceptions, class_name: "PackageException", foreign_key: "reported_by_id", dependent: :nullify
  has_many :resolved_exceptions, class_name: "PackageException", foreign_key: "resolved_by_id", dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :operation_logs, dependent: :nullify
  has_many :login_sessions, dependent: :destroy

  validates :phone, presence: true, uniqueness: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号格式不正确" }
  validates :employee_number, uniqueness: true, allow_blank: true
  validates :name, presence: true, length: { maximum: 50 }
  validates :password, length: { minimum: 6 }, allow_blank: true

  scope :active, -> { where(status: :enabled) }
  scope :by_role, ->(role) { where(role: role) }

  # 生成access_token（有效期2小时）
  def generate_access_token
    JWT.encode(
      {
        user_id: id,
        role: role,
        exp: 2.hours.from_now.to_i,
        token_type: "access"
      },
      Rails.application.credentials.secret_key_base
    )
  end

  # 生成refresh_token（有效期7天）
  def generate_refresh_token(remember_me = false)
    expires_in = remember_me ? 30.days : 7.days

    # 创建登录会话记录
    session = login_sessions.create!(
      refresh_token: SecureRandom.uuid,
      expires_at: expires_in.from_now,
      ip_address: nil
    )

    JWT.encode(
      {
        user_id: id,
        session_id: session.id,
        exp: expires_in.from_now.to_i,
        token_type: "refresh"
      },
      Rails.application.credentials.secret_key_base
    )
  end

  # 验证refresh_token并生成新的access_token
  def self.refresh_access_token(refresh_token)
    decoded = decode_jwt(refresh_token)
    return nil unless decoded
    return nil unless decoded[:token_type] == "refresh"

    user = User.find_by(id: decoded[:user_id], status: :enabled)
    return nil unless user

    session = user.login_sessions.find_by(id: decoded[:session_id])
    return nil unless session && session.active?

    # 生成新的access_token
    {
      access_token: user.generate_access_token,
      refresh_token: refresh_token # refresh_token保持不变
    }
  end

  def self.decode_jwt(token)
    decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError
    nil
  end

  # 检查token是否即将过期（剩余<30分钟）
  def self.token_needs_refresh?(token)
    decoded = decode_jwt(token)
    return false unless decoded

    exp = decoded[:exp]
    return false unless exp

    remaining_seconds = exp - Time.current.to_i
    remaining_seconds < 30.minutes.to_i
  end

  # 退出登录：销毁所有登录会话
  def logout_all_sessions
    login_sessions.destroy_all
  end

  # 获取当前活跃会话数
  def active_session_count
    login_sessions.valid.count
  end

  def admin?
    role == "admin"
  end

  def staff?
    role == "staff"
  end

  def customer?
    role == "customer"
  end

  def update_login_info(ip_address)
    update(last_login_at: Time.current, last_login_ip: ip_address)
  end
end
