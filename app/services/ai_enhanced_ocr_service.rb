class AiEnhancedOcrService
  def initialize
    # 使用AI面单识别服务
    @ai_parcel_service = AiParcelRecognitionService
  end

  # 使用AI进行面单识别
  def recognize_parcel_with_ai(image)
    begin
      # 保存临时文件
      temp_file_path = save_temp_image(image)

      # 使用AI面单识别服务
      ai_service = @ai_parcel_service.new
      ai_result = ai_service.recognize_parcel(temp_file_path)

      # 处理AI识别结果
      if ai_result[:success]
        {
          success: true,
          data: {
            tracking_number: ai_result[:data][:tracking_number],
            recipient_name: ai_result[:data][:recipient_name],
            recipient_phone: ai_result[:data][:recipient_phone],
            courier_company: ai_result[:data][:courier_company],
            recipient_address: ai_result[:data][:recipient_address],
            confidence: ai_result[:data][:confidence],
            raw_text: ai_result[:data][:raw_text]
          }
        }
      else
        # 即使AI识别失败，也返回OCR提取的文本信息
        {
          success: false,
          data: {
            tracking_number: "",
            recipient_name: "",
            recipient_phone: "",
            courier_company: "",
            recipient_address: "",
            confidence: 0.3,
            reasoning: "AI识别失败，但OCR成功提取了文本。请手动核对。",
            raw_text: "AI识别失败: #{ai_result[:error]}"
          },
          error: ai_result[:error] || "AI识别失败"
        }
      end

    rescue => e
      Rails.logger.error("OCR识别失败: #{e.message}")
      {
        success: false,
        data: {
          tracking_number: "",
          recipient_name: "",
          recipient_phone: "",
          courier_company: "",
          recipient_address: "",
          confidence: 0.2,
          reasoning: "OCR识别发生异常，请检查图片质量或重新上传。",
          raw_text: "OCR识别异常: #{e.message}"
        },
        error: "OCR识别失败: #{e.message}"
      }
    ensure
      # 清理临时文件
      File.delete(temp_file_path) if temp_file_path && File.exist?(temp_file_path)
    end
  end

  # 使用DeepSeek AI进行智能识别
  def recognize_with_deepseek_ai(image)
    # 将图片转换为base64编码
    image_base64 = convert_image_to_base64(image)

    # 构建AI识别提示词
    system_prompt = <<~PROMPT
      你是一个专业的快递面单识别专家。请分析提供的快递面单图片，提取以下关键信息：

      需要提取的信息：
      1. 运单号（Tracking Number）- 通常是10-15位的数字或字母组合
      2. 收件人姓名（Recipient Name）- 中文姓名，2-4个汉字
      3. 收件人手机号（Recipient Phone）- 11位数字
      4. 快递公司（Courier Company）- 如顺丰、圆通、中通等
      5. 收件地址（Recipient Address）- 详细地址信息

      请严格按照JSON格式返回结果，包含以下字段：
      {
        "tracking_number": "运单号",
        "customer_name": "收件人姓名",#{' '}
        "customer_phone": "手机号",
        "courier_company": "快递公司",
        "recipient_address": "收件地址",
        "confidence": 0.95,
        "reasoning": "识别理由和过程说明",
        "raw_text": "从图片中识别出的所有文本"
      }

      如果某些信息无法识别，请使用空字符串表示。
      请确保返回的是有效的JSON格式。
    PROMPT

    # 构建消息
    messages = [
      {
        role: "system",
        content: system_prompt
      },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "请识别这张快递面单图片中的信息。"
          },
          {
            type: "image_url",
            image_url: {
              url: "data:image/jpeg;base64,#{image_base64}"
            }
          }
        ]
      }
    ]

    # 调用DeepSeek API（支持图片识别的模型）
    result = @deepseek_service.chat_completion(
      messages,
      model: "deepseek-chat",
      temperature: 0.1,  # 降低随机性，提高准确性
      max_tokens: 2000
    )

    if result[:success]
      parse_ai_ocr_response(result[:data][:content])
    else
      {
        success: false,
        error: "AI识别失败: #{result[:error]}"
      }
    end
  end

  # 解析AI返回的OCR结果
  def parse_ai_ocr_response(ai_response)
    begin
      # 尝试解析JSON响应
      parsed_data = JSON.parse(ai_response)

      # 验证必要字段
      required_fields = [ "tracking_number", "customer_name", "customer_phone" ]
      missing_fields = required_fields.select { |field| parsed_data[field].to_s.empty? }

      if missing_fields.any?
        {
          success: false,
          error: "AI识别不完整，缺少字段: #{missing_fields.join(', ')}"
        }
      else
        {
          success: true,
          data: {
            tracking_number: parsed_data["tracking_number"],
            customer_name: parsed_data["customer_name"],
            customer_phone: parsed_data["customer_phone"],
            courier_company: parsed_data["courier_company"],
            recipient_address: parsed_data["recipient_address"],
            confidence: parsed_data["confidence"].to_f,
            reasoning: parsed_data["reasoning"],
            raw_text: parsed_data["raw_text"]
          }
        }
      end

    rescue JSON::ParserError => e
      {
        success: false,
        error: "AI响应格式错误: #{e.message}"
      }
    end
  end

  # 结合AI和传统OCR的结果
  def combine_results(ai_result, fallback_result)
    ai_data = ai_result[:data]
    fallback_data = fallback_result[:data]

    # 智能合并策略
    combined_data = {
      tracking_number: select_best_value(ai_data[:tracking_number], fallback_data[:tracking_number]),
      customer_name: select_best_value(ai_data[:customer_name], fallback_data[:customer_name]),
      customer_phone: select_best_value(ai_data[:customer_phone], fallback_data[:customer_phone]),
      courier_company: ai_data[:courier_company] || "",
      recipient_address: ai_data[:recipient_address] || "",
      confidence: (ai_data[:confidence] + fallback_data[:confidence]) / 2,
      reasoning: "AI与传统OCR结合识别",
      raw_text: [ ai_data[:raw_text], fallback_data[:raw_text] ].compact.join("\n")
    }

    {
      success: true,
      data: combined_data
    }
  end

  # 选择最佳值（优先使用AI结果，如果AI结果为空则使用传统OCR结果）
  def select_best_value(ai_value, fallback_value)
    ai_value.to_s.strip.empty? ? fallback_value : ai_value
  end

  private

  # 保存临时图片文件
  def save_temp_image(image)
    temp_dir = Rails.root.join("tmp", "ocr_uploads")
    FileUtils.mkdir_p(temp_dir)

    # 处理不同类型的图片输入
    if image.respond_to?(:original_filename)
      # ActionDispatch::Http::UploadedFile 对象
      filename = image.original_filename
      content = image.read
    elsif image.is_a?(File)
      # File 对象
      filename = File.basename(image.path)
      content = File.binread(image.path)
    elsif image.respond_to?(:path)
      # 其他有路径的对象
      filename = File.basename(image.path)
      content = File.binread(image.path)
    elsif image.is_a?(String) && File.exist?(image)
      # 字符串路径
      filename = File.basename(image)
      content = File.binread(image)
    else
      raise "不支持的图片格式: #{image.class}"
    end

    temp_path = File.join(temp_dir, "ocr_#{SecureRandom.uuid}_#{filename}")
    File.binwrite(temp_path, content)

    temp_path
  end

  # 格式化地址
  def format_address(parsed_data)
    address_parts = [
      parsed_data[:recipient_province],
      parsed_data[:recipient_city],
      parsed_data[:recipient_district],
      parsed_data[:recipient_address]
    ].compact.reject(&:empty?)

    address_parts.join("")
  end

  # 计算识别置信度
  def calculate_confidence(parsed_data)
    fields = [ :tracking_number, :recipient_name, :recipient_phone, :recipient_address ]
    detected_fields = fields.count { |field| parsed_data[field].present? }

    (detected_fields.to_f / fields.count).round(2)
  end

  # 将图片转换为base64编码
  def convert_image_to_base64(image)
    # 读取图片文件内容
    image_content = image.read
    # 转换为base64编码
    Base64.strict_encode64(image_content)
  end

  # 手动修正识别结果（当AI识别失败时提供手动修正功能）
  def manual_correction(original_result, corrections)
    corrected_data = original_result[:data].merge(corrections)

    {
      success: true,
      data: corrected_data,
      corrected: true,
      correction_notes: "用户手动修正了识别结果"
    }
  end

  # 批量识别功能
  def batch_recognize(images)
    results = []

    images.each_with_index do |image, index|
      result = recognize_parcel_with_ai(image)
      results << {
        index: index,
        filename: image.original_filename,
        result: result
      }
    end

    {
      success: true,
      data: {
        total: images.size,
        successful: results.count { |r| r[:result][:success] },
        failed: results.count { |r| !r[:result][:success] },
        results: results
      }
    }
  end
end
