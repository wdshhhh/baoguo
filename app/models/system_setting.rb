class SystemSetting < ApplicationRecord
  # 注意：updated_by是integer字段，用于存储用户ID，不使用belongs_to关联
  # 配置键常量
  SITE_NAME = "site_name"
  SITE_ADDRESS = "site_address"
  CONTACT_PHONE = "contact_phone"
  ADMIN_NAME = "admin_name"
  ADMIN_EMAIL = "admin_email"
  SERVICE_DESCRIPTION = "service_description"

  OVERDUE_DAYS = "overdue_days"
  OVERDUE_FEE_PER_DAY = "overdue_fee_per_day"
  MAX_STORAGE_DAYS = "max_storage_days"
  AUTO_MARK_EXCEPTION = "auto_mark_exception"
  EXCEPTION_DAYS = "exception_days"
  LARGE_PACKAGE_WEIGHT = "large_package_weight"

  WORK_START_TIME = "work_start_time"
  WORK_END_TIME = "work_end_time"
  BREAK_START_TIME = "break_start_time"
  BREAK_END_TIME = "break_end_time"
  WEEKEND_START_TIME = "weekend_start_time"
  WEEKEND_END_TIME = "weekend_end_time"
  HOLIDAY_OPEN = "holiday_open"
  HOLIDAY_START_TIME = "holiday_start_time"
  HOLIDAY_END_TIME = "holiday_end_time"

  SMS_NOTIFICATION = "sms_notification"
  EMAIL_NOTIFICATION = "email_notification"
  WECHAT_NOTIFICATION = "wechat_notification"
  NOTIFY_ON_STORED = "notify_on_stored"
  NOTIFY_BEFORE_OVERDUE = "notify_before_overdue"
  OVERDUE_NOTIFY_DAYS = "overdue_notify_days"

  # 默认配置
  DEFAULT_SETTINGS = {
    SITE_NAME => "菜鸟驿站",
    SITE_ADDRESS => "",
    CONTACT_PHONE => "13800138000",
    ADMIN_NAME => "",
    ADMIN_EMAIL => "",
    SERVICE_DESCRIPTION => "",

    OVERDUE_DAYS => "3",
    OVERDUE_FEE_PER_DAY => "1",
    MAX_STORAGE_DAYS => "15",
    AUTO_MARK_EXCEPTION => "true",
    EXCEPTION_DAYS => "7",
    LARGE_PACKAGE_WEIGHT => "5",

    WORK_START_TIME => "08:00",
    WORK_END_TIME => "18:00",
    BREAK_START_TIME => "12:00",
    BREAK_END_TIME => "13:00",
    WEEKEND_START_TIME => "09:00",
    WEEKEND_END_TIME => "17:00",
    HOLIDAY_OPEN => "false",
    HOLIDAY_START_TIME => "09:00",
    HOLIDAY_END_TIME => "17:00",

    SMS_NOTIFICATION => "true",
    EMAIL_NOTIFICATION => "false",
    WECHAT_NOTIFICATION => "false",
    NOTIFY_ON_STORED => "true",
    NOTIFY_BEFORE_OVERDUE => "true",
    OVERDUE_NOTIFY_DAYS => "1"
  }

  # 配置类型
  SETTING_TYPES = {
    SITE_NAME => { type: :string, label: "站点名称", required: true },
    SITE_ADDRESS => { type: :string, label: "站点地址", required: false },
    CONTACT_PHONE => { type: :string, label: "联系电话", required: true },
    ADMIN_NAME => { type: :string, label: "管理员姓名", required: false },
    ADMIN_EMAIL => { type: :string, label: "管理员邮箱", required: false },
    SERVICE_DESCRIPTION => { type: :text, label: "服务说明", required: false },

    OVERDUE_DAYS => { type: :integer, label: "免费存放天数", required: true, min: 1, max: 30 },
    OVERDUE_FEE_PER_DAY => { type: :float, label: "超期日收费", required: false, min: 0 },
    MAX_STORAGE_DAYS => { type: :integer, label: "最大存放天数", required: false, min: 1, max: 90 },
    AUTO_MARK_EXCEPTION => { type: :boolean, label: "自动标记异常", required: false },
    EXCEPTION_DAYS => { type: :integer, label: "异常标记天数", required: false, min: 1, max: 30 },
    LARGE_PACKAGE_WEIGHT => { type: :float, label: "大件阈值(kg)", required: false, min: 1 },

    WORK_START_TIME => { type: :time, label: "上班时间", required: false },
    WORK_END_TIME => { type: :time, label: "下班时间", required: false },
    BREAK_START_TIME => { type: :time, label: "午休开始", required: false },
    BREAK_END_TIME => { type: :time, label: "午休结束", required: false },
    WEEKEND_START_TIME => { type: :time, label: "周末上班", required: false },
    WEEKEND_END_TIME => { type: :time, label: "周末下班", required: false },
    HOLIDAY_OPEN => { type: :boolean, label: "节假日营业", required: false },
    HOLIDAY_START_TIME => { type: :time, label: "节假日上班", required: false },
    HOLIDAY_END_TIME => { type: :time, label: "节假日下班", required: false },

    SMS_NOTIFICATION => { type: :boolean, label: "短信通知", required: false },
    EMAIL_NOTIFICATION => { type: :boolean, label: "邮件通知", required: false },
    WECHAT_NOTIFICATION => { type: :boolean, label: "微信通知", required: false },
    NOTIFY_ON_STORED => { type: :boolean, label: "入库通知", required: false },
    NOTIFY_BEFORE_OVERDUE => { type: :boolean, label: "超期前通知", required: false },
    OVERDUE_NOTIFY_DAYS => { type: :integer, label: "超期提前天数", required: false, min: 1, max: 7 }
  }

  # 验证单个配置项
  def self.validate_setting(key, value)
    errors = []

    type_info = SETTING_TYPES[key]
    return errors unless type_info

    # 必填验证
    if type_info[:required] && (value.nil? || value.to_s.strip.empty?)
      errors << "#{type_info[:label]}不能为空"
      return errors
    end

    value = value.to_s.strip

    case key
    when SITE_NAME
      # 站点名称：2-50字符
      if value.length < 2 || value.length > 50
        errors << "#{type_info[:label]}长度必须在2-50字符之间"
      end

    when CONTACT_PHONE
      # 联系电话：11位手机号 或 座机号格式（区号-号码）
      phone_regex = /^(1[3-9]\d{9}|0\d{2,3}-\d{7,8})$/
      unless phone_regex.match?(value)
        errors << "#{type_info[:label]}格式不正确（11位手机号或区号-号码格式）"
      end

    when ADMIN_EMAIL
      # 邮箱格式验证
      if !value.empty? && !value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        errors << "#{type_info[:label]}格式不正确"
      end

    when OVERDUE_DAYS
      # 超期天数：正整数，1-30天
      days = value.to_i
      if days < 1 || days > 30
        errors << "#{type_info[:label]}必须是1-30之间的整数"
      end

    when OVERDUE_FEE_PER_DAY
      # 超期日收费：非负数
      fee = value.to_f
      if fee < 0
        errors << "#{type_info[:label]}不能为负数"
      end

    when MAX_STORAGE_DAYS
      # 最大存放天数：1-90天
      days = value.to_i
      if days < 1 || days > 90
        errors << "#{type_info[:label]}必须是1-90之间的整数"
      end

    when EXCEPTION_DAYS
      # 异常标记天数：1-30天
      days = value.to_i
      if days < 1 || days > 30
        errors << "#{type_info[:label]}必须是1-30之间的整数"
      end

    when LARGE_PACKAGE_WEIGHT
      # 大件阈值：大于0
      weight = value.to_f
      if weight <= 0
        errors << "#{type_info[:label]}必须大于0"
      end

    when WORK_START_TIME, WORK_END_TIME, BREAK_START_TIME, BREAK_END_TIME,
         WEEKEND_START_TIME, WEEKEND_END_TIME, HOLIDAY_START_TIME, HOLIDAY_END_TIME
      # 时间格式：HH:MM
      unless value.empty?
        time_regex = /^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/
        unless time_regex.match?(value)
          errors << "#{type_info[:label]}格式不正确（应为HH:MM格式）"
        end
      end

    when OVERDUE_NOTIFY_DAYS
      # 超期提前天数：1-7天
      days = value.to_i
      if days < 1 || days > 7
        errors << "#{type_info[:label]}必须是1-7之间的整数"
      end
    end

    errors
  end

  # 验证时间范围（上班时间不能晚于下班时间）
  def self.validate_time_range(start_time, end_time)
    errors = []

    return errors if start_time.blank? || end_time.blank?

    begin
      start = Time.parse(start_time)
      ending = Time.parse(end_time)

      if start > ending
        errors << "上班时间不能晚于下班时间"
      end
    rescue
      errors << "时间格式不正确"
    end

    errors
  end

  # 获取配置值
  def self.get(key)
    setting = find_by(key: key)
    setting ? setting.value : DEFAULT_SETTINGS[key]
  end

  # 设置配置值（带验证）
  def self.set(key, value, user = nil, ip_address = nil)
    # 先验证
    errors = validate_setting(key, value)
    raise errors.join("; ") if errors.any?

    setting = find_or_initialize_by(key: key)
    old_value = setting.value

    # 类型转换
    case SETTING_TYPES.dig(key, :type)
    when :integer
      value = value.to_i.to_s
    when :boolean
      value = value.to_s.downcase == "true" ? "true" : "false"
    end

    setting.value = value
    setting.updated_by = user.id if user
    setting.save!

    # 记录变更日志
    log_params = {
      key: key,
      old_value: old_value,
      new_value: value,
      ip_address: ip_address
    }
    log_params[:changed_by] = user.id if user
    SystemSettingLog.create!(log_params)

    setting
  end

  # 批量设置配置（带完整验证）
  def self.batch_set(settings, user = nil, ip_address = nil)
    all_errors = {}

    # 先验证所有配置项
    settings.each do |key, value|
      next unless DEFAULT_SETTINGS.key?(key)

      errors = validate_setting(key, value)
      all_errors[key] = errors if errors.any?
    end

    # 验证时间范围
    if settings.key?(WORK_START_TIME) && settings.key?(WORK_END_TIME)
      time_errors = validate_time_range(settings[WORK_START_TIME], settings[WORK_END_TIME])
      all_errors[:time_range] = time_errors if time_errors.any?
    end

    # 如果有验证错误，抛出异常
    if all_errors.any?
      raise all_errors.to_json
    end

    # 批量保存配置
    settings.each do |key, value|
      next unless DEFAULT_SETTINGS.key?(key)
      set(key, value, user, ip_address)
    end

    true
  end

  # 回滚到历史版本
  def self.rollback(log_id, user = nil, ip_address = nil)
    log = SystemSettingLog.find(log_id)
    raise "日志记录不存在" unless log

    set(log.key, log.old_value, user, ip_address)
    log
  end

  # 获取所有配置
  def self.all_settings
    settings = {}
    DEFAULT_SETTINGS.each_key do |key|
      settings[key] = get(key)
    end
    settings
  end

  # 重置为默认配置
  def self.reset_all(user = nil)
    DEFAULT_SETTINGS.each do |key, default_value|
      setting = find_or_initialize_by(key: key)
      old_value = setting.value
      setting.value = default_value
      setting.updated_by = user.id if user
      setting.save!

      log_params = {
        key: key,
        old_value: old_value,
        new_value: default_value,
        reset: true
      }
      log_params[:changed_by] = user.id if user
      SystemSettingLog.create!(log_params)
    end
    true
  end

  # 初始化默认配置
  def self.initialize_defaults
    DEFAULT_SETTINGS.each do |key, value|
      find_or_create_by(key: key) do |setting|
        setting.value = value
      end
    end
    true
  end

  # 获取配置类型信息
  def self.get_type_info(key)
    SETTING_TYPES[key] || { type: :string, label: key }
  end
end
