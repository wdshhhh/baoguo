module Api
  module V1
    class CourierAiController < ApplicationController
      skip_before_action :verify_authenticity_token
      # before_action :authenticate_user!

      # AI助手对话接口
      def chat
        user_message = params[:message]
        conversation_history = params[:history] || []

        return render json: { success: false, error: "message is required" }, status: :bad_request unless user_message.present?

        # 使用AI助手服务处理消息
        ai_service = CourierAiAssistantService.new
        result = ai_service.process_message(user_message, conversation_history)

        if result[:success]
          render json: {
            success: true,
            response: result[:data][:response],
            type: result[:data][:type],
            packages: result[:data][:packages] || [],
            knowledge_key: result[:data][:knowledge_key]
          }
        else
          render json: { success: false, error: result[:error] }
        end
      end

      # 获取快捷问题列表
      def quick_questions
        ai_service = CourierAiAssistantService.new
        result = ai_service.get_quick_questions

        render json: result
      end

      # 获取知识库内容
      def knowledge_base
        key = params[:key]

        if key.present? && CourierAiAssistantService::KNOWLEDGE_BASE.key?(key.to_sym)
          knowledge = CourierAiAssistantService::KNOWLEDGE_BASE[key.to_sym]
          render json: {
            success: true,
            data: {
              key: key,
              title: knowledge[:title],
              content: knowledge[:content]
            }
          }
        else
          # 返回所有知识库条目
          knowledge_list = CourierAiAssistantService::KNOWLEDGE_BASE.map do |k, v|
            { key: k, title: v[:title] }
          end
          render json: {
            success: true,
            data: knowledge_list
          }
        end
      end

      # 生成运营简报
      def daily_report
        # 获取统计数据
        package_stats = {
          today_packages: Package.where("DATE(created_at) = ?", Date.today).count,
          delivered: Package.where(status: "picked_up").where("DATE(picked_up_at) = ?", Date.today).count,
          pending: Package.where(status: "pending").count,
          exceptions: PackageException.where("DATE(created_at) = ?", Date.today).count
        }

        ai_service = CourierAiAssistantService.new
        result = ai_service.generate_daily_report(package_stats)

        render json: result
      end

      # 包裹查询接口
      def package_search
        conditions = {}

        if params[:tracking_number].present?
          conditions[:tracking_number] = params[:tracking_number]
        elsif params[:phone].present?
          conditions[:phone] = params[:phone]
        elsif params[:name].present?
          conditions[:name] = params[:name]
        else
          return render json: { success: false, error: "请提供查询条件（运单号、手机号或姓名）" }, status: :bad_request
        end

        # 实际查询数据库
        packages = Package.all
        packages = packages.where(tracking_number: conditions[:tracking_number]) if conditions[:tracking_number]
        packages = packages.where(recipient_phone: conditions[:phone]) if conditions[:phone]
        packages = packages.where("recipient_name LIKE ?", "%#{conditions[:name]}%") if conditions[:name]

        packages = packages.limit(10).order(created_at: :desc)

        response_data = packages.map do |pkg|
          {
            id: pkg.id,
            tracking_number: pkg.tracking_number,
            recipient_name: pkg.recipient_name,
            recipient_phone: pkg.recipient_phone,
            courier_company: pkg.courier_company,
            status: pkg.status,
            pickup_code: pkg.pickup_code,
            stored_at: pkg.stored_at,
            picked_up_at: pkg.picked_up_at
          }
        end

        render json: {
          success: true,
          data: response_data,
          count: response_data.size
        }
      end

      # 清空对话历史
      def clear_history
        # 在实际应用中，这里可以清除服务器端存储的对话历史
        render json: {
          success: true,
          message: "对话历史已清空"
        }
      end
    end
  end
end
