class SystemSetting < ApplicationRecord
  enum setting_type: { string: 0, number: 1, boolean: 2, json: 3 }

  validates :key, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  scope :by_key, ->(key) { find_by(key: key) }

  def self.get(key, default = nil)
    setting = find_by(key: key)
    return default unless setting
    setting.typed_value
  end

  def self.set(key, value, description: nil, setting_type: :string)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.description = description if description
    setting.setting_type = setting_type
    setting.save!
    setting
  end

  def typed_value
    case setting_type
    when "number"
      value.to_f
    when "boolean"
      value == "true"
    when "json"
      JSON.parse(value)
    else
      value
    end
  end

  def self.default_settings
    {
      "site_name" => { value: "菜鸟驿站包裹管理系统", type: :string, description: "站点名称" },
      "overdue_days" => { value: "3", type: :number, description: "包裹滞留天数阈值" },
      "max_storage_days" => { value: "7", type: :number, description: "最大存储天数" },
      "enable_sms_notification" => { value: "true", type: :boolean, description: "是否启用短信通知" },
      "enable_push_notification" => { value: "true", type: :boolean, description: "是否启用推送通知" },
      "work_start_time" => { value: "09:00", type: :string, description: "工作时间开始" },
      "work_end_time" => { value: "20:00", type: :string, description: "工作时间结束" },
      "pickup_code_format" => { value: "MMDD####", type: :string, description: "取件码格式" }
    }
  end

  def self.initialize_defaults
    default_settings.each do |key, config|
      set(key, config[:value], description: config[:description], setting_type: config[:type])
    end
  end
end
