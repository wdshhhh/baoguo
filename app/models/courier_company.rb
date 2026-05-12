class CourierCompany < ApplicationRecord
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :logo_url, length: { maximum: 255 }
  validates :contact_phone, format: { with: /\A1[3-9]\d{9}\z/, allow_blank: true }

  scope :active, -> { where(status: :enabled) }

  enum :status, { disabled: 0, enabled: 1 }, default: 1

  def self.select_options
    active.order(name: :asc).map { |c| [c.name, c.id] }
  end

  def self.by_code(code)
    find_by(code: code)
  end
end