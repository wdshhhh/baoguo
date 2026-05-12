module Api
  module V1
    class AiAssistantController < ApplicationController
      skip_before_action :verify_authenticity_token
      # before_action :authenticate_user!

      def assistant
        prompt = params[:prompt]
        conversation_history = params[:history] || []

        return render json: { error: "prompt is required" }, status: :bad_request unless prompt.present?

        response = call_ai_api(prompt, conversation_history)

        if response
          render json: { success: true, response: response }
        else
          render json: { success: false, response: "抱歉，AI服务暂时不可用，请稍后重试。" }
        end
      end

      def validate_ocr
        ocr_data = params[:ocr_data]
        return render json: { error: "ocr_data is required" }, status: :bad_request unless ocr_data.present?

        validation_result = validate_ocr_data(ocr_data)

        render json: {
          success: true,
          confidence: validation_result[:confidence],
          summary: validation_result[:summary],
          suggestions: validation_result[:suggestions],
          checks: validation_result[:checks],
          corrections: validation_result[:corrections]
        }
      end

      def analyze_exceptions
        exceptions = params[:exceptions] || []

        result = analyze_exception_patterns(exceptions)

        render json: {
          success: true,
          summary: result[:summary],
          patterns: result[:patterns],
          suggestions: result[:suggestions],
          statistics: result[:statistics]
        }
      end

      def get_suggestion
        context = params[:context] || "general"

        suggestion = generate_suggestion(context)

        render json: {
          success: true,
          suggestion: suggestion[:text],
          type: suggestion[:type],
          priority: suggestion[:priority]
        }
      end

      def quick_actions
        render json: {
          success: true,
          actions: [
            { id: "validate_ocr", label: "🧠 校验OCR数据", description: "检查识别结果的准确性", icon: "check" },
            { id: "analyze_exceptions", label: "📊 分析异常包裹", description: "找出异常包裹的规律", icon: "alert" },
            { id: "optimize_workflow", label: "⚡ 优化工作流程", description: "获取效率提升建议", icon: "zap" },
            { id: "report_summary", label: "📈 生成日报摘要", description: "快速了解今日运营情况", icon: "bar-chart" },
            { id: "help", label: "❓ 帮助中心", description: "获取系统使用帮助", icon: "help-circle" }
          ]
        }
      end

      private

      def call_ai_api(prompt, history = [])
        api_key = ENV["AI_API_KEY"] || "sk-929d94d767b245ca92521ae631338c71"
        api_url = ENV["AI_API_URL"] || "https://api.openai.com/v1/chat/completions"

        begin
          # 构建系统提示词
          system_prompt = build_system_prompt

          # 构建消息历史
          messages = [ { role: "system", content: system_prompt } ]

          # 添加历史记录
          history.each do |item|
            messages << { role: item[:role], content: item[:content] }
          end

          # 添加当前用户消息
          messages << { role: "user", content: prompt }

          response = HTTParty.post(
            api_url,
            headers: {
              "Authorization" => "Bearer #{api_key}",
              "Content-Type" => "application/json"
            },
            body: {
              model: "gpt-3.5-turbo",
              messages: messages,
              temperature: 0.5,
              max_tokens: 1000
            }.to_json,
            timeout: 30
          )

          if response.success?
            response.parsed_response["choices"][0]["message"]["content"]
          else
            Rails.logger.error "AI API error: #{response.code} - #{response.body}"
            nil
          end
        rescue StandardError => e
          Rails.logger.error "AI API error: #{e.message}"
          nil
        end
      end

      def build_system_prompt
        <<~PROMPT
          你是一个智能包裹管理系统的AI助手"驿站小助手"，你的职责是帮助驿站工作人员高效管理包裹。

          【系统功能】
          - 包裹管理：入库、出库、查询、异常处理
          - OCR识别：自动识别快递面单信息
          - 用户管理：管理收件人信息
          - 统计报表：查看运营数据

          【你的能力】
          1. OCR数据校验：分析识别结果的准确性，提供修正建议
          2. 异常分析：帮助识别异常包裹的模式和原因
          3. 操作指导：提供系统功能的使用说明
          4. 智能查询：回答关于包裹状态、统计数据等问题
          5. 效率建议：提供工作流程优化建议

          【回复要求】
          - 使用友好、专业的语言
          - 回答简洁明了，避免冗长
          - 对于不确定的问题，如实说明并提供建议
          - 支持中文和自然语言交互

          【示例场景】
          - "帮我检查这个运单号是否正确"
          - "最近为什么异常包裹增多了？"
          - "如何快速处理大量包裹？"
          - "今天入库了多少包裹？"

          请以专业、友好的态度为用户提供帮助！
        PROMPT
      end

      def validate_ocr_data(ocr_data)
        tracking_number = ocr_data[:tracking_number]
        recipient_name = ocr_data[:recipient_name]
        recipient_phone = ocr_data[:recipient_phone]
        courier_company = ocr_data[:courier_company]

        suggestions = []
        checks = []
        corrections = {}

        # 校验手机号
        if recipient_phone.present?
          phone_clean = recipient_phone.gsub(/\D/, "")
          if phone_clean.length == 11 && phone_clean.start_with?("1") && phone_clean[1] =~ /[3-9]/
            checks << { field: "手机号", valid: true, message: "格式正确" }
          else
            checks << { field: "手机号", valid: false, message: "格式不正确" }
            suggestions << "请检查手机号格式是否正确（应为11位数字，以1开头）"

            # 提供修正建议
            if phone_clean.length == 10 && phone_clean =~ /^[3-9]/
              corrections[:recipient_phone] = "1" + phone_clean
              suggestions << "建议修正为：#{corrections[:recipient_phone]}"
            elsif phone_clean.length == 11 && phone_clean.start_with?("1") && phone_clean[1] =~ /[0-2]/
              corrected = "1" + [ "3", "5", "7", "8" ][rand(4)] + phone_clean[2..10]
              corrections[:recipient_phone] = corrected
              suggestions << "建议修正为：#{corrected}"
            end
          end
        else
          checks << { field: "手机号", valid: false, message: "缺失" }
          suggestions << "请补充手机号信息"
        end

        # 校验运单号
        if tracking_number.present?
          tn_clean = tracking_number.upcase.gsub(/[^A-Z0-9]/, "")
          if tn_clean.length >= 12 && tn_clean.length <= 18
            checks << { field: "运单号", valid: true, message: "长度合理" }

            # 检查格式
            if tn_clean =~ /^[A-Z]{2}[0-9]+$/
              checks << { field: "运单号格式", valid: true, message: "格式正确" }
            else
              checks << { field: "运单号格式", valid: false, message: "格式不标准" }
              suggestions << "运单号格式不标准，通常应为两位字母前缀+数字"
            end
          else
            checks << { field: "运单号", valid: false, message: "长度异常" }
            suggestions << "运单号长度应在12-18位之间"
          end
        else
          checks << { field: "运单号", valid: false, message: "缺失" }
          suggestions << "请补充运单号信息"
        end

        # 校验收件人姓名
        if recipient_name.present?
          name_clean = recipient_name.gsub(/[^\u4e00-\u9fa5a-zA-Z0-9]/, "")
          if name_clean.length >= 2 && name_clean.length <= 20
            checks << { field: "收件人", valid: true, message: "格式正确" }
          else
            checks << { field: "收件人", valid: false, message: "长度异常" }
            suggestions << "收件人姓名长度应在2-20个字符之间"
          end
        else
          checks << { field: "收件人", valid: false, message: "缺失" }
          suggestions << "请补充收件人信息"
        end

        # 校验快递公司
        known_couriers = [ "顺丰速运", "中通快递", "圆通速递", "申通快递", "韵达快递", "EMS", "京东物流" ]
        if courier_company.present?
          if known_couriers.include?(courier_company)
            checks << { field: "快递公司", valid: true, message: "名称正确" }
          else
            checks << { field: "快递公司", valid: false, message: "名称不常见" }
            suggestions << "快递公司名称 '#{courier_company}' 不常见，请确认是否正确"
          end
        else
          checks << { field: "快递公司", valid: false, message: "缺失" }
          suggestions << "请选择快递公司"
        end

        # 校验运单号前缀与快递公司是否匹配
        if tracking_number.present? && courier_company.present?
          prefix_mapping = {
            "SF" => "顺丰速运",
            "ZT" => "中通快递",
            "YT" => "圆通速递",
            "ST" => "申通快递",
            "YD" => "韵达快递",
            "JD" => "京东物流",
            "EMS" => "EMS"
          }
          prefix = tracking_number.upcase[0..1]
          if prefix_mapping.key?(prefix) && prefix_mapping[prefix] != courier_company
            checks << { field: "运单号与快递公司匹配", valid: false, message: "不匹配" }
            suggestions << "运单号前缀#{prefix}通常对应#{prefix_mapping[prefix]}，但当前选择的是#{courier_company}"
            corrections[:courier_company] = prefix_mapping[prefix]
          elsif prefix_mapping.key?(prefix)
            checks << { field: "运单号与快递公司匹配", valid: true, message: "匹配正确" }
          end
        end

        # 计算置信度
        valid_count = checks.count { |c| c[:valid] }
        confidence = (valid_count.to_f / checks.size * 100).round

        summary = if confidence >= 90
          "数据校验通过，所有字段格式正确，可直接创建包裹"
        elsif confidence >= 70
          "数据基本正常，部分字段建议确认后再创建包裹"
        elsif confidence >= 50
          "数据存在一些问题，建议仔细检查并修正"
        else
          "数据存在较多问题，请修正后再创建包裹"
        end

        {
          confidence: confidence,
          summary: summary,
          suggestions: suggestions.empty? ? [ "数据格式正常，可直接创建包裹" ] : suggestions,
          checks: checks,
          corrections: corrections
        }
      end

      def analyze_exception_patterns(exceptions)
        return {
          summary: "没有提供异常数据",
          patterns: [],
          suggestions: [],
          statistics: {}
        } if exceptions.empty?

        stats = {
          total: exceptions.size,
          by_type: {},
          by_courier: {},
          by_time: {}
        }

        exceptions.each do |e|
          # 按类型统计
          type = e[:type] || "其他"
          stats[:by_type][type] = (stats[:by_type][type] || 0) + 1

          # 按快递公司统计
          courier = e[:courier_company] || "未知"
          stats[:by_courier][courier] = (stats[:by_courier][courier] || 0) + 1

          # 按时间段统计
          time = e[:created_at] || Time.now.to_s
          hour = time.to_s[11..12] || "未知"
          stats[:by_time][hour] = (stats[:by_time][hour] || 0) + 1
        end

        # 找出异常最多的类型
        top_type = stats[:by_type].max_by { |k, v| v }
        top_courier = stats[:by_courier].max_by { |k, v| v }
        top_time = stats[:by_time].max_by { |k, v| v }

        patterns = []
        suggestions = []

        if top_type
          patterns << "最常见的异常类型：#{top_type[0]}（#{top_type[1]}次）"
          suggestions << "建议重点关注#{top_type[0]}类型的异常处理流程"
        end

        if top_courier
          patterns << "#{top_courier[0]}快递公司异常最多（#{top_courier[1]}次）"
          suggestions << "建议与#{top_courier[0]}快递公司沟通，了解异常原因"
        end

        if top_time
          patterns << "异常高发时段：#{top_time[0]}点（#{top_time[1]}次）"
          suggestions << "建议在#{top_time[0]}点前后增加人力投入"
        end

        if exceptions.size > 10
          patterns << "异常数量较多，建议批量处理"
          suggestions << "可以考虑设置自动处理规则或批量操作功能"
        end

        {
          summary: "共分析#{exceptions.size}条异常记录，发现#{patterns.size}个主要模式",
          patterns: patterns,
          suggestions: suggestions,
          statistics: stats
        }
      end

      def generate_suggestion(context)
        suggestions = {
          general: [
            { text: "提示：您可以使用OCR识别功能快速录入包裹信息，系统会自动校验数据准确性。", type: "info", priority: "medium" },
            { text: "建议：定期清理超过7天的待取件包裹，避免占用货架空间。", type: "tip", priority: "high" },
            { text: "技巧：使用批量操作功能可以大幅提高处理效率。", type: "tip", priority: "medium" }
          ],
          ocr: [
            { text: "提示：上传清晰的快递面单照片可以提高OCR识别准确率。", type: "info", priority: "high" },
            { text: "建议：识别结果可以手动编辑，确认无误后再创建包裹。", type: "tip", priority: "high" },
            { text: "技巧：使用AI校验功能可以帮助发现潜在的数据问题。", type: "tip", priority: "medium" }
          ],
          packages: [
            { text: "提示：待取件包裹超过3天未取会自动转为异常状态。", type: "info", priority: "high" },
            { text: "建议：出库时请仔细核对取件码和收件人信息。", type: "tip", priority: "high" },
            { text: "技巧：使用筛选功能可以快速定位特定状态的包裹。", type: "tip", priority: "medium" }
          ],
          exceptions: [
            { text: "提示：异常包裹需要在24小时内处理完毕。", type: "info", priority: "high" },
            { text: "建议：分析异常原因，尝试从源头解决问题。", type: "tip", priority: "medium" },
            { text: "技巧：使用AI分析功能可以发现异常模式和规律。", type: "tip", priority: "medium" }
          ],
          dashboard: [
            { text: "提示：首页展示的是今日实时数据。", type: "info", priority: "medium" },
            { text: "建议：关注异常数量指标，及时处理问题。", type: "tip", priority: "high" },
            { text: "技巧：点击统计卡片可以查看详细数据。", type: "tip", priority: "low" }
          ]
        }

        context_suggestions = suggestions[context.to_sym] || suggestions[:general]
        context_suggestions.sample
      end
    end
  end
end
