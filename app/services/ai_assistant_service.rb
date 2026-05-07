class AiAssistantService
  def initialize
    @deepseek_service = DeepseekApiService.new(ENV["DEEPSEEK_API_KEY"])
  end

  # 处理用户消息
  def process_message(user_message, conversation_history = [], current_user = nil)
    begin
      # 构建系统提示词，让AI了解项目功能
      system_prompt = build_system_prompt(current_user)

      # 构建对话消息
      messages = build_messages(system_prompt, user_message, conversation_history)

      # 调用DeepSeek API
      result = @deepseek_service.chat_completion(messages, temperature: 0.7, max_tokens: 2000)

      if result[:success]
        # 解析AI回复并生成建议操作
        ai_response = result[:data][:content]
        suggested_actions = generate_suggested_actions(ai_response, user_message)

        {
          success: true,
          data: {
            response: ai_response,
            suggested_actions: suggested_actions,
            api_usage: result[:data][:usage],
            timestamp: Time.current.iso8601
          }
        }
      else
        # API调用失败时使用回退响应
        generate_fallback_response(user_message)
      end

    rescue => e
      {
        success: false,
        error: "AI助手处理失败: #{e.message}"
      }
    end
  end

  private

  # 构建系统提示词
  def build_system_prompt(current_user)
    user_role = current_user&.role || "customer"

    <<~PROMPT
      你是一个专业的快递驿站AI助手，专门帮助用户更好地使用快递驿站系统。

      系统功能概述：
      1. 包裹管理：查询包裹状态、添加包裹、修改包裹信息、删除包裹
      2. 客户自助：客户可以通过运单号或手机号查询包裹、取件
      3. 异常处理：处理包裹异常情况（破损、丢失、逾期等）
      4. 数据统计：查看包裹流量、异常统计、运营报表
      5. AI功能：智能包裹分类、异常预测、数据分析等

      用户角色：#{user_role}

      请根据用户的问题提供准确、有用的帮助：
      - 如果是包裹查询相关，请引导用户使用运单号或手机号查询
      - 如果是取件问题，请说明取件流程和注意事项
      - 如果是异常处理，请提供处理建议和联系方式
      - 如果是功能使用问题，请详细说明操作步骤
      - 保持友好、专业、耐心的服务态度

      请用中文回复，回复内容要具体、实用，避免过于笼统。
      如果问题需要人工处理，请引导用户联系人工客服。
    PROMPT
  end

  # 构建对话消息
  def build_messages(system_prompt, user_message, conversation_history)
    messages = [
      { role: "system", content: system_prompt }
    ]

    # 添加对话历史（最多保留最近5轮）
    recent_history = conversation_history.last(10)
    recent_history.each do |msg|
      messages << { role: msg["role"], content: msg["content"] }
    end

    # 添加当前用户消息
    messages << { role: "user", content: user_message }

    messages
  end

  # 生成建议操作
  def generate_suggested_actions(ai_response, user_message)
    actions = []

    # 根据AI回复内容生成相关操作建议
    response_text = ai_response.downcase
    user_text = user_message.downcase

    # 包裹查询相关
    if response_text.include?("查询") || response_text.include?("包裹") || user_text.include?("查询") || user_text.include?("包裹")
      actions << "查看包裹详情"
      actions << "输入运单号查询"
    end

    # 取件相关
    if response_text.include?("取件") || user_text.include?("取件")
      actions << "查看取件流程"
      actions << "联系取件点"
    end

    # 地址位置相关
    if response_text.include?("地址") || response_text.include?("位置") || user_text.include?("地址") || user_text.include?("位置")
      actions << "查看地图位置"
      actions << "导航到驿站"
    end

    # 营业时间相关
    if response_text.include?("时间") || response_text.include?("营业") || user_text.include?("时间") || user_text.include?("营业")
      actions << "查看营业时间"
    end

    # 费用相关
    if response_text.include?("费用") || response_text.include?("收费") || user_text.include?("费用") || user_text.include?("收费")
      actions << "查看收费标准"
    end

    # 异常处理相关
    if response_text.include?("异常") || response_text.include?("问题") || response_text.include?("投诉") ||
       user_text.include?("异常") || user_text.include?("问题") || user_text.include?("投诉")
      actions << "查看异常处理"
      actions << "联系人工客服"
    end

    # 默认操作
    if actions.empty?
      actions << "继续咨询"
      actions << "联系人工客服"
    end

    actions.uniq
  end

  # 生成回退响应（当API失败时使用）
  def generate_fallback_response(user_message)
    message = user_message.downcase

    # 根据用户消息类型生成相应的回退回复
    if message.include?("查询") || message.include?("包裹")
      response = "我可以帮您查询包裹状态。请提供运单号或手机号码，或者前往包裹管理页面查看。"
      actions = [ "输入运单号查询", "前往包裹管理", "联系人工客服" ]
    elsif message.include?("取件")
      response = "取件流程：1. 凭取件码到驿站 2. 出示身份证明 3. 签字确认。营业时间：8:00-20:00"
      actions = [ "查看取件流程", "联系取件点" ]
    elsif message.include?("地址") || message.include?("位置")
      response = "驿站地址：XX市XX区XX街道XX号。您可以使用地图应用导航到驿站。"
      actions = [ "查看地图位置", "导航到驿站" ]
    elsif message.include?("时间") || message.include?("营业")
      response = "营业时间：周一至周日 8:00-20:00。节假日正常营业。"
      actions = [ "查看营业时间" ]
    elsif message.include?("费用") || message.include?("收费")
      response = "收费标准：普通包裹3元/件，大件包裹5元/件，文件类2元/件。存储超过3天加收1元/天。"
      actions = [ "查看收费标准" ]
    elsif message.include?("你好") || message.include?("您好")
      response = "您好！我是快递驿站AI助手，很高兴为您服务。请问有什么可以帮您？"
      actions = [ "查询包裹", "取件咨询", "营业信息" ]
    else
      response = "我理解您的问题了。为了更好地帮助您，请提供更多详细信息，或者联系人工客服获得更专业的帮助。"
      actions = [ "重新描述问题", "联系人工客服" ]
    end

    {
      success: true,
      data: {
        response: response,
        suggested_actions: actions,
        api_usage: {},
        timestamp: Time.current.iso8601
      }
    }
  end
end
