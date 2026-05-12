namespace :system_settings do
  desc "清理90天前的配置变更日志"
  task cleanup_logs: :environment do
    deleted_count = SystemSettingLog.cleanup_expired_logs(90)
    puts "清理完成，共删除 #{deleted_count} 条过期日志"
  end
end
