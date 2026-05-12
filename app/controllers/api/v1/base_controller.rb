module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!
      before_action :set_pagination_params

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from StandardError, with: :internal_server_error
      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      # 用于存储需要刷新的token
      attr_accessor :new_token

      private

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized("缺少认证令牌") unless token

        # 开发环境支持模拟token
        if Rails.env.development? && token == "mock-token-123456"
          @current_user = User.find_or_create_by(phone: "13800138000") do |u|
            u.name = "管理员"
            u.password = "123456"
            u.password_confirmation = "123456"
            u.role = "admin"
            u.status = "enabled"
          end
          return
        end

        decoded = User.decode_jwt(token)
        return render_unauthorized("无效的认证令牌") unless decoded

        # 验证token类型必须是access_token
        return render_unauthorized("无效的token类型") unless decoded[:token_type] == "access"

        @current_user = User.find_by(id: decoded[:user_id], status: :enabled)
        render_unauthorized("用户不存在或已被禁用") unless @current_user

        # 检查token是否即将过期（剩余<30分钟），如果是则生成新token
        refresh_token_if_needed(decoded)
      end

      def refresh_token_if_needed(decoded)
        exp = decoded[:exp]
        return unless exp

        remaining_seconds = exp - Time.current.to_i
        thirty_minutes_seconds = 30 * 60

        # 如果剩余时间小于30分钟，生成新token
        if remaining_seconds < thirty_minutes_seconds
          @new_token = @current_user.generate_access_token
        end
      end

      def current_user
        @current_user
      end

      def authorize_staff!
        unless current_user.staff? || current_user.admin?
          render_forbidden("只有工作人员可以执行此操作")
        end
      end

      def user_not_authorized
        render_forbidden("您没有权限执行此操作")
      end

      def set_pagination_params
        @page = params[:page] || 1
        @per_page = params[:per_page] || 20
      end

      def render_json(data, status: :ok, meta: {})
        response = { data: data }
        response[:meta] = meta if meta.present?
        response[:new_token] = @new_token if @new_token.present?
        render json: response, status: status
      end

      def render_error(message, status: :unprocessable_entity, errors: nil)
        response = { error: message }
        response[:errors] = errors if errors
        render json: response, status: status
      end

      def render_unauthorized(message = "未授权")
        render_error(message, status: :unauthorized)
      end

      def render_forbidden(message = "禁止访问")
        render_error(message, status: :forbidden)
      end

      def not_found(exception)
        render_error("资源不存在", status: :not_found)
      end

      def unprocessable_entity(exception)
        render_error("数据验证失败", status: :unprocessable_entity, errors: exception.record.errors.full_messages)
      end

      def internal_server_error(exception)
        Rails.logger.error exception.message
        Rails.logger.error exception.backtrace.join("\n")
        render_error("服务器内部错误", status: :internal_server_error)
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end
