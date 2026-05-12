class SystemSettingLog < ApplicationRecord
  # changed_by是integer字段，存储用户ID，不使用belongs_to关联

  # 获取配置标签
  def setting_label
    SystemSetting::SETTING_TYPES.dig(key, :label) || key
  end

  # 获取变更用户名称
  def changed_by_name
    return "系统" unless changed_by.present?
    user = User.find_by(id: changed_by)
    user&.name || "未知用户"
  end

  # 获取变更类型描述
  def change_type
    reset ? "重置" : "修改"
  end

  # 格式化时间
  def formatted_time
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  # 获取格式化的新旧值
  def formatted_old_value
    format_value(old_value)
  end

  def formatted_new_value
    format_value(new_value)
  end

  private

  def format_value(value)
    return "" unless value.present?
    
    # 处理布尔值显示
    if value == "true"
      "开启"
    elsif value == "false"
      "关闭"
    else
      value
    end
  end

  public

  # 清理过期日志（保留90天）
  def self.cleanup_expired_logs(days_to_keep = 90)
    cutoff_date = days_to_keep.days.ago
    deleted_count = where("created_at < ?", cutoff_date).delete_all
    Rails.logger.info("清理了 #{deleted_count} 条#{days_to_keep}天前的配置变更日志")
    deleted_count
  end

  # 获取配置项的历史记录
  def self.get_history(key, limit = 20)
    where(key: key).order(created_at: :desc).limit(limit)
  end
end
