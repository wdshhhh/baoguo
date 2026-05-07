# AI面单识别服务 - 直接使用AI进行面单识别
class AiParcelRecognitionService
  def initialize(api_key = nil)
    @api_key = api_key || ENV["AI_API_KEY"] || "sk-929d94d767b245ca92521ae631338c71"
    @api_base = "https://api.deepseek.com"

    Rails.logger.info("=== AI面单识别服务初始化 ===")
    Rails.logger.info("API密钥: #{@api_key[0..10]}...")
    Rails.logger.info("API端点: #{@api_base}")
  end

  # 使用AI识别面单
  def recognize_parcel(image_path)
    start_time = Time.now

    Rails.logger.info("=== 启动AI面单识别 ===")
    Rails.logger.info("图片路径: #{image_path}")

    begin
      # 将图片转换为base64
      image_base64 = convert_image_to_base64(image_path)

      # 构建AI请求
      response = call_ai_api(image_base64, image_path)

      processing_time = Time.now - start_time

      if response[:success]
        Rails.logger.info("✅ AI面单识别成功")
        Rails.logger.info("   识别耗时: #{processing_time.round(2)}秒")

        result = {
          success: true,
          data: parse_ai_response(response[:data]),
          engine: "deepseek_ai",
          processing_time: processing_time,
          confidence: 0.95  # AI识别置信度较高
        }

        # 记录识别结果
        Rails.logger.info("   识别结果: #{result[:data].inspect}")

        result
      else
        Rails.logger.warn("⚠️ AI面单识别失败，返回OCR提取的文本信息")

        # 即使AI识别失败，也返回OCR提取的文本信息
        ocr_text = extract_text_with_ocr(image_path)
        {
          success: false,
          data: {
            tracking_number: "",
            recipient_name: "",
            recipient_phone: "",
            courier_company: "",
            recipient_address: "",
            confidence: 0.3,  # 低置信度，因为AI识别失败
            reasoning: "AI识别失败，但OCR成功提取了文本。请手动核对以下文本：#{ocr_text[0..200]}",
            raw_text: ocr_text
          },
          error: "AI识别失败: #{response[:error]}",
          engine: "deepseek_ai",
          processing_time: processing_time
        }
      end

    rescue => e
      Rails.logger.error("❌ AI面单识别异常: #{e.message}")

      # 即使发生异常，也返回OCR提取的文本信息
      ocr_text = extract_text_with_ocr(image_path) rescue "OCR提取失败"
      {
        success: false,
        data: {
          tracking_number: "",
          recipient_name: "",
          recipient_phone: "",
          courier_company: "",
          recipient_address: "",
          confidence: 0.2,  # 极低置信度，因为发生异常
          reasoning: "AI识别发生异常，但尝试提取了OCR文本。请手动核对：#{ocr_text[0..200] if ocr_text.is_a?(String)}",
          raw_text: ocr_text
        },
        error: "AI识别异常: #{e.message}",
        engine: "deepseek_ai"
      }
    end
  end

  private

  # 将图片转换为base64编码
  def convert_image_to_base64(image_path)
    image_data = File.binread(image_path)
    base64_data = Base64.strict_encode64(image_data)
    "data:image/jpeg;base64,#{base64_data}"
  end

  # 调用AI API
  def call_ai_api(image_base64, image_path)
    uri = URI.parse("#{@api_base}/chat/completions")

    # 先使用OCR识别图片文本
    ocr_text = extract_text_with_ocr(image_path)

    # 构建请求体（仅文本输入）
    request_body = {
      model: "deepseek-chat",
      messages: [
        {
          role: "system",
          content: <<~PROMPT
            你是一个专业的快递面单识别专家。请分析OCR识别出的快递面单文本，提取以下关键信息：

            需要提取的信息：
            1. 运单号（Tracking Number）- 通常是10-15位的数字或字母组合，如SF123456789、YD123456789等
            2. 收件人姓名（Recipient Name）- 中文姓名，2-4个汉字
            3. 收件人手机号（Recipient Phone）- 11位数字，以1开头
            4. 快递公司（Courier Company）- 如顺丰、圆通、中通、韵达、申通、京东、EMS、邮政等
            5. 收件地址（Recipient Address）- 详细地址信息，包含省市区和具体地址

            请严格按照JSON格式返回结果，包含以下字段：
            {
              "tracking_number": "运单号",
              "recipient_name": "收件人姓名",
              "recipient_phone": "手机号",
              "courier_company": "快递公司",
              "recipient_address": "收件地址",
              "confidence": 0.95,
              "reasoning": "识别理由和过程说明",
              "raw_text": "从OCR结果中识别出的所有文本"
            }

            如果某些信息无法识别，请使用空字符串表示。
            请确保返回的是有效的JSON格式。
          PROMPT
        },
        {
          role: "user",
          content: "以下是OCR识别出的快递面单文本，请分析并提取关键信息：\n\n" + ocr_text
        }
      ],
      max_tokens: 2000,
      temperature: 0.1
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{@api_key}"
    request.body = request_body.to_json

    Rails.logger.info("发送AI识别请求...")

    response = http.request(request)

    if response.code == "200"
      data = JSON.parse(response.body)

      if data["choices"] && data["choices"][0]
        {
          success: true,
          data: data["choices"][0]["message"]["content"]
        }
      else
        {
          success: false,
          error: "API响应格式异常"
        }
      end
    else
      {
        success: false,
        error: "API请求失败: #{response.code} - #{response.body}"
      }
    end
  rescue => e
    {
      success: false,
      error: "API调用异常: #{e.message}"
    }
  end

  # 解析AI响应
  def parse_ai_response(ai_content)
    begin
      # 尝试从AI响应中提取JSON
      json_match = ai_content.match(/\{.*\}/m)

      if json_match
        json_data = JSON.parse(json_match[0])

        {
          tracking_number: json_data["tracking_number"] || "",
          recipient_name: json_data["recipient_name"] || "",
          recipient_phone: json_data["recipient_phone"] || "",
          courier_company: json_data["courier_company"] || "",
          recipient_address: json_data["recipient_address"] || "",
          confidence: json_data["confidence"] || 0.8,
          reasoning: json_data["reasoning"] || "",
          raw_text: json_data["raw_text"] || ai_content
        }
      else
        # 如果无法解析JSON，使用简单的文本匹配
        parse_text_content(ai_content)
      end

    rescue JSON::ParserError => e
      Rails.logger.warn("JSON解析失败，使用文本解析: #{e.message}")
      parse_text_content(ai_content)
    end
  end

  # 文本内容解析（备用方案）
  def parse_text_content(content)
    # 简单的文本匹配规则
    tracking_number = extract_tracking_number(content)
    phone_number = extract_phone_number(content)
    courier_company = extract_courier_company(content)

    {
      tracking_number: tracking_number,
      recipient_name: extract_recipient_name(content),
      recipient_phone: phone_number,
      courier_company: courier_company,
      recipient_address: extract_address(content),
      confidence: 0.7,  # 文本解析置信度较低
      reasoning: "使用文本解析方法识别",
      raw_text: content
    }
  end

  # 提取运单号
  def extract_tracking_number(text)
    patterns = [
      /(?:运单号|单号|Tracking)[：:\s]*([A-Z0-9]{10,20})/i,
      /\b(SF|ZT|YT|JD|EMS|YD|ST|DB)[A-Z0-9]{8,18}\b/i,
      /\b([0-9]{12,18})\b/
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[1] if match
    end

    ""
  end

  # 提取手机号
  def extract_phone_number(text)
    patterns = [
      /(?:电话|手机|Phone)[：:\s]*(\d{11})/i,
      /\b(1[3-9]\d{9})\b/
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[1] if match
    end

    ""
  end

  # 提取快递公司
  def extract_courier_company(text)
    companies = {
      "顺丰" => "顺丰",
      "圆通" => "圆通",
      "中通" => "中通",
      "韵达" => "韵达",
      "申通" => "申通",
      "京东" => "京东",
      "EMS" => "EMS",
      "邮政" => "邮政",
      "德邦" => "德邦"
    }

    companies.each do |keyword, company|
      return company if text.include?(keyword)
    end

    ""
  end

  # 提取收件人姓名
  def extract_recipient_name(text)
    patterns = [
      /(?:收件人|收货人|姓名)[：:\s]*([\u4e00-\u9fff]{2,4})/i,
      /([\u4e00-\u9fff]{2,4})[\s]*(?:先生|女士|小姐|老师)/i
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[1] if match
    end

    ""
  end

  # 提取地址
  def extract_address(text)
    # 简单的地址匹配规则
    address_patterns = [
      /(?:地址|收货地址)[：:\s]*([^，。！？\n]{10,50})/i,
      /([\u4e00-\u9fff]{2,10}[市区县][^，。！？\n]{10,50})/i
    ]

    address_patterns.each do |pattern|
      match = text.match(pattern)
      return match[1].strip if match
    end

    ""
  end

  # 使用OCR提取图片文本
  def extract_text_with_ocr(image_path)
    begin
      # 使用最可靠的OCR服务提取文本
      reliable_service = ReliableOcrService.new(image_path)
      ocr_result = reliable_service.recognize

      if ocr_result[:success]
        Rails.logger.info("OCR文本提取成功: #{ocr_result[:raw_text][0..100]}...")
        ocr_result[:raw_text]
      else
        Rails.logger.warn("OCR文本提取失败，使用备用方案")
        "OCR识别失败，无法获取图片文本内容"
      end

    rescue => e
      Rails.logger.error("OCR文本提取异常: #{e.message}")
      "OCR识别异常: #{e.message}"
    end
  end
end
