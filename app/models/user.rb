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

  validates :phone, presence: true, uniqueness: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号格式不正确" }
  validates :employee_number, uniqueness: true, allow_blank: true
  validates :name, presence: true, length: { maximum: 50 }
  validates :password, length: { minimum: 6 }, allow_blank: true

  scope :active, -> { where(status: :enabled) }
  scope :by_role, ->(role) { where(role: role) }

  def generate_jwt
    JWT.encode(
      {
        user_id: id,
        role: role,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base
    )
  end

  def self.decode_jwt(token)
    decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError
    nil
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
