module Api
  module V1
    class SystemSettingsController < BaseController
      before_action :authenticate_user!

      # GET /api/v1/system_settings
      def index
        authorize SystemSetting
        settings = SystemSetting.all_settings
        render_json(settings)
      end

      # GET /api/v1/system_settings/:key
      def show
        authorize SystemSetting
        key = params[:id] || params[:key]
        value = SystemSetting.get(key)
        if value.nil?
          render_error("配置项不存在", status: :not_found)
        else
          render_json({ key: key, value: value })
        end
      end

      # PUT /api/v1/system_settings/:key
      def update
        authorize SystemSetting
        key = params[:id] || params[:key]
        value = params[:value]

        unless SystemSetting::DEFAULT_SETTINGS.key?(key)
          return render_error("不支持的配置项", status: :bad_request)
        end

        begin
          # 获取客户端IP
          ip_address = request.remote_ip
          SystemSetting.set(key, value, current_user, ip_address)
          render_json({ message: "配置更新成功", key: key, value: SystemSetting.get(key) })
        rescue => e
          render_error("更新配置失败: #{e.message}")
        end
      end

      # PUT /api/v1/system_settings/batch_update
      def batch_update
        authorize SystemSetting, :batch_update?
        settings = params[:settings]
        return render_error("请提供配置数据") unless settings.present?

        begin
          # 获取客户端IP
          ip_address = request.remote_ip
          SystemSetting.batch_set(settings, current_user, ip_address)
          render_json({ message: "批量更新配置成功" })
        rescue => e
          # 尝试解析JSON错误
          begin
            errors = JSON.parse(e.message)
            render_error("配置验证失败", status: :unprocessable_entity, data: errors)
          rescue
            render_error("批量更新配置失败: #{e.message}")
          end
        end
      end

      # POST /api/v1/system_settings/reset
      def reset
        authorize SystemSetting, :reset?
        unless params[:confirm] == "true"
          return render_error("请确认重置操作")
        end

        begin
          SystemSetting.reset_all(current_user)
          render_json({ message: "配置已重置为默认值" })
        rescue => e
          render_error("重置配置失败: #{e.message}")
        end
      end

      # POST /api/v1/system_settings/initialize_defaults
      def initialize_defaults
        begin
          SystemSetting.initialize_defaults
          render_json({ message: "默认配置初始化成功" })
        rescue => e
          render_error("初始化配置失败: #{e.message}")
        end
      end

      # GET /api/v1/system_settings/logs
      def logs
        authorize SystemSetting, :logs?
        # 支持按配置项筛选
        key_filter = params[:key]

        query = SystemSettingLog.order(created_at: :desc)
        query = query.where(key: key_filter) if key_filter.present?

        logs = query.limit(100).map do |log|
          {
            id: log.id,
            key: log.key,
            setting_label: log.setting_label,
            old_value: log.formatted_old_value,
            new_value: log.formatted_new_value,
            raw_old_value: log.old_value,
            raw_new_value: log.new_value,
            changed_by: log.changed_by_name,
            change_type: log.change_type,
            created_at: log.formatted_time
          }
        end
        render_json(logs)
      end

      # POST /api/v1/system_settings/rollback
      def rollback
        authorize SystemSetting, :rollback?
        log_id = params[:log_id]
        return render_error("请提供日志ID") unless log_id.present?

        begin
          ip_address = request.remote_ip
          log = SystemSetting.rollback(log_id, current_user, ip_address)
          render_json({
            message: "配置已回滚",
            key: log.key,
            setting_label: log.setting_label,
            restored_value: log.old_value
          })
        rescue => e
          render_error("回滚失败: #{e.message}")
        end
      end

      # GET /api/v1/system_settings/logs/history/:key
      def history
        authorize SystemSetting, :history?
        key = params[:key]
        return render_error("请提供配置项") unless key.present?

        logs = SystemSettingLog.get_history(key, 20).map do |log|
          {
            id: log.id,
            key: log.key,
            setting_label: log.setting_label,
            old_value: log.formatted_old_value,
            new_value: log.formatted_new_value,
            changed_by: log.changed_by_name,
            change_type: log.change_type,
            created_at: log.formatted_time
          }
        end
        render_json(logs)
      end
    end
  end
end
