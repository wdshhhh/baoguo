class OcrRecord < ApplicationRecord
  belongs_to :user
  belongs_to :package, optional: true

  serialize :parsed_data, JSON

  # 识别状态
  enum :status, {
    pending: 0,
    success: 1,
    failed: 2
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.today.all_day) }
  scope :this_week, -> { where(created_at: Date.today.beginning_of_week..Date.today.end_of_week) }

  # 搜索方法
  def self.search(keyword)
    return all unless keyword.present?
    
    where("parsed_data LIKE ? OR raw_text LIKE ?", 
          "%#{keyword}%", "%#{keyword}%")
  end

  # 统计今日识别次数
  def self.today_count
    today.count
  end

  # 统计本周识别次数
  def self.week_count
    this_week.count
  end

  # 计算识别成功率
  def self.success_rate
    total = recent.count
    return 0.0 if total == 0
    (success.count.to_f / total * 100).round(2)
  end

  # 计算平均识别耗时
  def self.avg_processing_time
    records = recent.where.not(processing_time: nil)
    return 0.0 if records.empty?
    (records.sum(:processing_time).to_f / records.count).round(2)
  end
end
