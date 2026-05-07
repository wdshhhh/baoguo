class OcrService
  # 快递面单OCR识别
  # 支持百度、阿里云等通用OCR接口格式
  def recognize_parcel(image)
    begin
      # 模拟OCR识别结果（实际项目中应调用真实OCR接口）
      # 这里使用模拟数据演示，实际集成时替换为真实API调用

      # 解析图片数据（实际项目中应处理图片上传和格式转换）
      image_data = process_image(image)

      # 调用OCR API（这里使用模拟数据）
      ocr_result = simulate_ocr_api_call(image_data)

      # 解析OCR结果
      parsed_data = parse_ocr_result(ocr_result)

      {
        success: true,
        data: {
          tracking_number: parsed_data[:tracking_number],
          customer_name: parsed_data[:customer_name],
          customer_phone: parsed_data[:customer_phone],
          confidence: parsed_data[:confidence],
          raw_text: parsed_data[:raw_text]
        }
      }

    rescue => e
      {
        success: false,
        error: "OCR识别失败: #{e.message}"
      }
    end
  end

  private

  def process_image(image)
    # 实际项目中处理图片上传和格式转换
    # 这里返回模拟的图片数据
    {
      filename: image.original_filename,
      size: image.size,
      content_type: image.content_type
    }
  end

  def simulate_ocr_api_call(image_data)
    # 模拟OCR API调用结果
    # 实际项目中应替换为真实的OCR服务调用

    # 模拟不同的快递面单格式
    mock_results = [
      {
        text: "顺丰速运 SF1234567890 张三 13800138000 北京市朝阳区",
        confidence: 0.95
      },
      {
        text: "圆通快递 YT9876543210 李四 13900139000 上海市浦东新区",
        confidence: 0.92
      },
      {
        text: "中通快递 ZT5678901234 王五 13600136000 广州市天河区",
        confidence: 0.90
      },
      {
        text: "韵达快递 YD3456789012 赵六 13700137000 深圳市南山区",
        confidence: 0.88
      }
    ]

    # 随机选择一种结果模拟不同面单
    mock_results.sample
  end

  def parse_ocr_result(ocr_result)
    text = ocr_result[:text]
    confidence = ocr_result[:confidence]

    # 解析运单号（常见快递公司运单号格式）
    tracking_number = extract_tracking_number(text)

    # 解析姓名（中文姓名，2-4个字符）
    customer_name = extract_customer_name(text)

    # 解析手机号（11位数字）
    customer_phone = extract_customer_phone(text)

    {
      tracking_number: tracking_number,
      customer_name: customer_name,
      customer_phone: customer_phone,
      confidence: confidence,
      raw_text: text
    }
  end

  def extract_tracking_number(text)
    # 常见快递公司运单号格式
    patterns = [
      /SF\d{10,12}/,     # 顺丰
      /YT\d{10,12}/,     # 圆通
      /ZT\d{10,12}/,     # 中通
      /YD\d{10,12}/,     # 韵达
      /STO\d{10,12}/,    # 申通
      /JD\d{10,12}/,     # 京东
      /\d{12,14}/        # 通用数字格式
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[0] if match
    end

    nil
  end

  def extract_customer_name(text)
    # 匹配中文姓名（2-4个中文字符）
    name_pattern = /[\u4e00-\u9fa5]{2,4}/
    matches = text.scan(name_pattern)

    # 通常姓名出现在运单号之后
    tracking_number = extract_tracking_number(text)
    if tracking_number
      tracking_index = text.index(tracking_number)
      names_after_tracking = matches.select do |name|
        text.index(name) > tracking_index if text.index(name)
      end
      return names_after_tracking.first if names_after_tracking.any?
    end

    matches.first
  end

  def extract_customer_phone(text)
    # 匹配11位手机号
    phone_pattern = /1[3-9]\d{9}/
    match = text.match(phone_pattern)
    match ? match[0] : nil
  end

  # 实际OCR API调用方法（示例代码）
  def call_real_ocr_api(image_data)
    # 百度OCR API调用示例
    # access_token = get_baidu_access_token
    # response = HTTParty.post(
    #   'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic',
    #   headers: {
    #     'Content-Type' => 'application/x-www-form-urlencoded'
    #   },
    #   body: {
    #     access_token: access_token,
    #     image: Base64.encode64(image_data),
    #     detect_direction: true,
    #     paragraph: true
    #   }
    # )

    # 阿里云OCR API调用示例
    # client = Aliyun::Oss::Client.new(
    #   endpoint: 'your_endpoint',
    #   access_key_id: 'your_access_key_id',
    #   access_key_secret: 'your_access_key_secret'
    # )
    # response = client.recognize_character(
    #   image: image_data,
    #   output_word_info: true
    # )

    # 返回解析后的结果
    # parse_api_response(response)
  end

  def get_baidu_access_token
    # 获取百度OCR访问令牌
    # response = HTTParty.post(
    #   'https://aip.baidubce.com/oauth/2.0/token',
    #   body: {
    #     grant_type: 'client_credentials',
    #     client_id: 'your_api_key',
    #     client_secret: 'your_secret_key'
    #   }
    # )
    # response['access_token']
  end
end
