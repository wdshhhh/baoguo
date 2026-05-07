class DeepseekApiService
  BASE_URL = "https://api.deepseek.com/v1"

  def initialize(api_key = nil)
    @api_key = api_key || ENV["DEEPSEEK_API_KEY"]
  end

  # 发送聊天消息到DeepSeek API
  def chat_completion(messages, model: "deepseek-chat", temperature: 0.7, max_tokens: 2000)
    begin
      response = HTTParty.post(
        "#{BASE_URL}/chat/completions",
        headers: headers,
        body: {
          model: model,
          messages: messages,
          temperature: temperature,
          max_tokens: max_tokens,
          stream: false
        }.to_json
      )

      if response.success?
        parse_chat_response(response)
      else
        handle_api_error(response)
      end
    rescue => e
      {
        success: false,
        error: "DeepSeek API调用失败: #{e.message}"
      }
    end
  end

  # 智能包裹分类
  def intelligent_package_classification(ocr_text)
    system_prompt = <<~PROMPT
      你是一个专业的快递驿站AI助手，专门负责包裹分类和识别。
      请根据提供的包裹信息（OCR识别结果）进行智能分类。

      包裹类型分类标准：
      - 易碎物品：包含"易碎"、"玻璃"、"陶瓷"、"fragile"等关键词
      - 大件包裹：包含"大件"、"重型"、"体积大"、"large"等关键词
      - 优先包裹：包含"优先"、"加急"、"urgent"、"priority"等关键词
      - 文件类：包含"文件"、"文档"、"信件"、"document"等关键词
      - 普通包裹：其他情况

      请返回JSON格式的结果，包含：
      - package_type: 包裹类型（fragile/large/priority/document/normal）
      - priority_level: 优先级（high/medium/low）
      - estimated_weight: 预估重量（kg）
      - special_handling: 特殊处理需求数组
      - confidence: 分类置信度（0-1）
      - reasoning: 分类理由
    PROMPT

    user_message = "包裹信息：#{ocr_text}"

    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: user_message }
    ]

    result = chat_completion(messages, temperature: 0.3)

    if result[:success]
      parse_classification_result(result[:data])
    else
      result
    end
  end

  # 智能客服聊天
  def intelligent_customer_service(user_message, conversation_history = [])
    system_prompt = <<~PROMPT
      你是一个专业的快递驿站AI客服助手，专门处理客户咨询和问题解答。

      服务范围包括：
      1. 包裹查询：帮助客户查询包裹状态、位置、预计到达时间
      2. 取件指导：提供取件流程、取件码使用说明
      3. 营业信息：提供驿站地址、营业时间、联系方式
      4. 费用咨询：解释收费标准、优惠活动
      5. 问题处理：处理包裹异常、投诉建议
      6. 一般咨询：回答其他相关问题

      请保持专业、友好、耐心的服务态度，用中文回复。
      如果问题需要人工处理，请引导客户联系人工客服。
    PROMPT

    messages = [
      { role: "system", content: system_prompt }
    ]

    # 添加上下文历史
    conversation_history.each do |msg|
      messages << { role: msg[:role], content: msg[:content] }
    end

    messages << { role: "user", content: user_message }

    chat_completion(messages, temperature: 0.7)
  end

  # 异常预测分析
  def intelligent_exception_prediction(package_data)
    system_prompt = <<~PROMPT
      你是一个专业的快递异常预测AI，专门分析包裹异常风险。
      请根据包裹信息预测潜在异常风险。

      分析维度：
      1. 包裹类型风险：易碎物品、大件包裹等
      2. 存储时间风险：长时间未取件的包裹
      3. 天气因素：恶劣天气对包裹的影响
      4. 历史模式：相似包裹的异常历史
      5. 客户行为：客户取件习惯分析

      请返回JSON格式的风险分析结果。
    PROMPT

    user_message = "包裹数据：#{package_data.to_json}"

    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: user_message }
    ]

    chat_completion(messages, temperature: 0.4)
  end

  # 数据分析报告生成
  def generate_intelligent_report(report_data, report_type)
    system_prompt = <<~PROMPT
      你是一个专业的数据分析AI，专门生成快递驿站运营报告。
      请根据提供的数据生成专业的分析报告。

      报告类型：#{report_type}
      请提供深入的数据洞察和业务建议。
    PROMPT

    user_message = "数据：#{report_data.to_json}"

    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: user_message }
    ]

    chat_completion(messages, temperature: 0.5, max_tokens: 3000)
  end

  private

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{@api_key}"
    }
  end

  def parse_chat_response(response)
    data = JSON.parse(response.body)

    {
      success: true,
      data: {
        content: data["choices"][0]["message"]["content"],
        usage: data["usage"],
        model: data["model"]
      }
    }
  rescue => e
    {
      success: false,
      error: "API响应解析失败: #{e.message}"
    }
  end

  def parse_classification_result(api_response)
    content = api_response[:content]

    # 尝试解析JSON格式的响应
    begin
      result = JSON.parse(content)
      {
        success: true,
        data: result
      }
    rescue JSON::ParserError
      # 如果不是JSON格式，尝试提取关键信息
      extract_classification_from_text(content)
    end
  end

  def extract_classification_from_text(text)
    # 简单的文本解析逻辑
    package_type = if text.include?("易碎") then "fragile"
    elsif text.include?("大件") then "large"
    elsif text.include?("优先") then "priority"
    elsif text.include?("文件") then "document"
    else "normal"
    end

    {
      success: true,
      data: {
        package_type: package_type,
        priority_level: "medium",
        estimated_weight: 1.5,
        special_handling: [],
        confidence: 0.8,
        reasoning: text
      }
    }
  end

  def handle_api_error(response)
    error_message = case response.code
    when 401 then "API密钥无效"
    when 403 then "API访问被拒绝"
    when 429 then "API调用频率超限"
    when 500 then "DeepSeek服务器内部错误"
    else "API调用失败: #{response.code}"
    end

    {
      success: false,
      error: error_message
    }
  end
end
