module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!
      before_action :set_pagination_params

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from StandardError, with: :internal_server_error

      private

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized("缺少认证令牌") unless token

        decoded = User.decode_jwt(token)
        return render_unauthorized("无效的认证令牌") unless decoded

        @current_user = User.find_by(id: decoded[:user_id], status: :enabled)
        render_unauthorized("用户不存在或已被禁用") unless @current_user
      end

      def current_user
        @current_user
      end

      def authorize_staff!
        unless current_user.staff? || current_user.admin?
          render_forbidden("只有工作人员可以执行此操作")
        end
      end

      def set_pagination_params
        @page = params[:page] || 1
        @per_page = params[:per_page] || 20
      end

      def render_json(data, status: :ok, meta: {})
        response = { data: data }
        response[:meta] = meta if meta.present?
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
