module Api
  module V1
    class AiAssistantController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/ai/assistant
      # AI助手对话接口
      def assistant
        begin
          unless params[:message]
            return render_error("请提供对话消息")
          end

          # 创建AI助手服务实例
          assistant_service = AiAssistantService.new

          # 处理用户消息
          result = assistant_service.process_message(
            params[:message],
            params[:conversation_history] || [],
            current_user
          )

          if result[:success]
            render_json(result[:data])
          else
            render_error(result[:error])
          end

        rescue => e
          Rails.logger.error("AI助手处理失败: #{e.message}")
          render_error("AI助手处理失败: #{e.message}")
        end
      end
    end
  end
end
