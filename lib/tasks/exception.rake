namespace :exception do
  desc "自动标记滞留异常：将超过设定天数未取件的包裹标记为滞留异常"
  task auto_mark_overdue: :environment do
    # 获取系统设置中的超期天数
    overdue_days = SystemSetting.overdue_days.to_i
    auto_mark_enabled = SystemSetting.auto_mark_exception == 'true'
    
    puts "=== 自动标记滞留异常任务 ==="
    puts "自动标记状态: #{auto_mark_enabled ? '开启' : '关闭'}"
    puts "超期天数设置: #{overdue_days}天"
    
    return unless auto_mark_enabled
    
    # 查找超过设定天数未取件的已入库包裹
    cutoff_time = overdue_days.days.ago
    packages_to_mark = Package.stored.where("stored_at < ?", cutoff_time)
    
    puts "找到 #{packages_to_mark.count} 个超期未取件的包裹"
    
    packages_to_mark.each do |package|
      begin
        # 使用系统用户或第一个管理员用户来标记异常
        system_user = User.find_by(role: 'admin') || User.first
        
        next unless system_user
        
        package.mark_exception!(
          :overdue,
          "包裹滞留超过#{overdue_days}天未取件，系统自动标记",
          system_user
        )
        
        puts "已标记包裹 #{package.tracking_number} 为滞留异常"
      rescue => e
        puts "标记包裹 #{package.tracking_number} 失败: #{e.message}"
      end
    end
    
    puts "=== 任务完成 ==="
  end
end
