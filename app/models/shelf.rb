class Shelf < ApplicationRecord
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :location, length: { maximum: 100 }
  validates :capacity, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(status: :enabled) }

  enum :status, { disabled: 0, enabled: 1 }, default: 1

  # 获取货架当前使用数量
  def current_usage
    Package.where(shelf_id: id, status: [:pending, :stored]).count
  end

  # 获取货架使用率
  def usage_rate
    return 0 if capacity == 0
    (current_usage.to_f / capacity * 100).round(1)
  end

  def self.select_options
    active.order(name: :asc).map { |s| [s.name, s.id] }
  end
end