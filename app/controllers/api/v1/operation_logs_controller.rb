module Api
  module V1
    class OperationLogsController < BaseController
      # GET /api/v1/operation_logs
      # 获取操作日志列表
      def index
        authorize OperationLog

        query = OperationLog.recent

        # 按操作类型筛选
        if params[:action].present?
          query = query.by_action(params[:action])
        end

        # 按用户筛选
        if params[:user_id].present?
          query = query.by_user(params[:user_id])
        elsif !current_user.admin?
          # 非管理员只能查看自己的日志
          query = query.by_user(current_user.id)
        end

        # 按资源类型筛选
        if params[:resource_type].present?
          query = query.where(resource_type: params[:resource_type])
        end

        # 按时间范围筛选
        if params[:start_date].present? && params[:end_date].present?
          query = query.by_date_range(
            Date.parse(params[:start_date]).beginning_of_day,
            Date.parse(params[:end_date]).end_of_day
          )
        elsif params[:start_date].present?
          query = query.where("created_at >= ?", Date.parse(params[:start_date]).beginning_of_day)
        elsif params[:end_date].present?
          query = query.where("created_at <= ?", Date.parse(params[:end_date]).end_of_day)
        end

        # 关键词搜索（用户名、资源ID）
        if params[:keyword].present?
          search_term = "%#{params[:keyword]}%"
          query = query.joins(:user).where(
            "users.name LIKE ? OR users.phone LIKE ? OR operation_logs.resource_id LIKE ?",
            search_term, search_term, search_term
          )
        end

        logs = query.page(@page).per(@per_page)

        render_json(
          logs.map { |log| log_info(log) },
          meta: pagination_meta(logs)
        )
      end

      # GET /api/v1/operation_logs/:id
      # 获取日志详情
      def show
        log = OperationLog.find(params[:id])
        authorize log
        render_json(log_detail_info(log))
      rescue ActiveRecord::RecordNotFound
        render_error("日志记录不存在", status: :not_found)
      end

      # POST /api/v1/operation_logs/export
      # 导出日志
      def export
        authorize OperationLog, :export?

        query = OperationLog.recent

        # 应用筛选条件
        if params[:start_date].present? && params[:end_date].present?
          query = query.by_date_range(
            Date.parse(params[:start_date]).beginning_of_day,
            Date.parse(params[:end_date]).end_of_day
          )
        end

        if params[:action].present?
          query = query.by_action(params[:action])
        end

        if params[:user_id].present?
          query = query.by_user(params[:user_id])
        end

        logs = query.order(created_at: :desc)

        case params[:type]
        when "csv"
          send_data generate_csv(logs),
                    filename: "operation_logs_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                    type: "text/csv"
        when "excel"
          send_data generate_excel(logs),
                    filename: "operation_logs_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
                    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        else
          render_error("不支持的导出格式", status: :bad_request)
        end
      rescue => e
        render_error("导出失败: #{e.message}")
      end

      private

      def log_info(log)
        {
          id: log.id,
          action: log.action,
          action_name: action_name(log.action),
          user: log.user.present? ? {
            id: log.user.id,
            name: log.user.name,
            phone: log.user.phone,
            role: log.user.role
          } : nil,
          resource_type: log.resource_type,
          resource_type_name: resource_type_name(log.resource_type),
          resource_id: log.resource_id,
          details: log.details,
          ip_address: log.ip_address,
          user_agent: log.user_agent,
          created_at: log.created_at.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      def log_detail_info(log)
        info = log_info(log)
        info.merge!({
          updated_at: log.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        })
      end

      def action_name(action)
        {
          "user_login" => "用户登录",
          "user_logout" => "用户退出",
          "user_register" => "用户注册",
          "user_created" => "创建用户",
          "user_updated" => "更新用户",
          "user_deleted" => "删除用户",
          "user_password_reset" => "重置密码",
          "user_role_updated" => "更新角色",
          "user_enabled" => "启用用户",
          "user_disabled" => "禁用用户",
          "user_self_password_changed" => "修改密码",
          "package_created" => "创建包裹",
          "package_updated" => "更新包裹",
          "package_deleted" => "删除包裹",
          "package_stored" => "包裹入库",
          "package_picked_up" => "包裹出库",
          "package_exception_marked" => "标记异常",
          "package_import" => "批量导入",
          "exception_created" => "创建异常",
          "exception_processed" => "处理异常",
          "exception_resolved" => "解决异常",
          "exception_deleted" => "删除异常",
          "exception_batch_processing" => "批量处理异常",
          "exception_batch_resolved" => "批量解决异常",
          "system_settings_updated" => "更新系统设置",
          "system_settings_reset" => "重置系统设置",
          "system_settings_rollback" => "回滚系统设置"
        }[action] || action
      end

      def resource_type_name(type)
        return nil unless type
        {
          "Package" => "包裹",
          "User" => "用户",
          "PackageException" => "异常记录",
          "SystemSetting" => "系统设置"
        }[type] || type
      end

      def generate_csv(logs)
        headers = [ "操作时间", "操作类型", "操作人", "操作人手机号", "角色", "资源类型", "资源ID", "IP地址", "详情" ]

        CSV.generate(encoding: "UTF-8") do |csv|
          csv << headers

          logs.each do |log|
            csv << [
              log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
              action_name(log.action),
              log.user&.name || "-",
              log.user&.phone || "-",
              log.user&.role || "-",
              resource_type_name(log.resource_type) || "-",
              log.resource_id || "-",
              log.ip_address || "-",
              log.details || "-"
            ]
          end
        end
      end

      def generate_excel(logs)
        require "axlsx"

        Axlsx::Package.new do |p|
          p.workbook.add_worksheet(name: "操作日志") do |sheet|
            sheet.add_row [ "操作时间", "操作类型", "操作人", "操作人手机号", "角色", "资源类型", "资源ID", "IP地址", "详情" ]

            logs.each do |log|
              sheet.add_row [
                log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
                action_name(log.action),
                log.user&.name || "-",
                log.user&.phone || "-",
                log.user&.role || "-",
                resource_type_name(log.resource_type) || "-",
                log.resource_id || "-",
                log.ip_address || "-",
                log.details || "-"
              ]
            end

            sheet.column_widths 18, 12, 10, 12, 10, 10, 10, 15, 30
          end
        end.to_stream.read
      end
    end
  end
end
