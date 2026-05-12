class TesseractOcrService
  require 'rtesseract'
  require 'mini_magick'

  def initialize(image_path)
    @image_path = image_path
    @processed_image_path = nil
  end

  def recognize
    begin
      # 图片预处理
      preprocess_image

      # 使用Tesseract进行OCR识别
      result = RTesseract.new(@processed_image_path || @image_path, lang: 'chi_sim+eng')
      raw_text = result.to_s

      # 解析识别结果
      parsed_data = parse_ocr_result(raw_text)

      # 计算各字段置信度
      confidence_data = calculate_confidence(raw_text, parsed_data)

      {
        success: true,
        data: {
          tracking_number: parsed_data[:tracking_number],
          recipient_name: parsed_data[:recipient_name],
          recipient_phone: parsed_data[:recipient_phone],
          recipient_address: parsed_data[:recipient_address],
          courier_company: parsed_data[:courier_company],
          weight: parsed_data[:weight],
          tracking_number_confidence: confidence_data[:tracking_number_confidence],
          recipient_name_confidence: confidence_data[:recipient_name_confidence],
          recipient_phone_confidence: confidence_data[:recipient_phone_confidence],
          recipient_address_confidence: confidence_data[:recipient_address_confidence],
          courier_company_confidence: confidence_data[:courier_company_confidence],
          overall_confidence: confidence_data[:overall_confidence]
        },
        raw_text: raw_text
      }
    rescue => e
      Rails.logger.error("Tesseract OCR识别失败: #{e.message}")
      {
        success: false,
        error: "OCR识别失败: #{e.message}"
      }
    ensure
      # 清理临时处理图片
      File.delete(@processed_image_path) if @processed_image_path && File.exist?(@processed_image_path)
    end
  end

  private

  def preprocess_image
    begin
      # 使用MiniMagick进行图片预处理
      image = MiniMagick::Image.open(@image_path)

      # 转换为灰度图
      image = image.grayscale

      # 调整对比度（增强文字清晰度）
      image = image.level("0%,100%,1.5")

      # 去噪处理
      image = image.median_blur(1)

      # 二值化处理
      image = image.threshold("50%")

      # 保存处理后的图片
      @processed_image_path = @image_path.gsub(/\.[^.]+$/, '_processed.png')
      image.write(@processed_image_path)

    rescue => e
      Rails.logger.warn("图片预处理失败，使用原图进行识别: #{e.message}")
    end
  end

  def parse_ocr_result(text)
    {
      tracking_number: extract_tracking_number(text),
      recipient_name: extract_recipient_name(text),
      recipient_phone: extract_recipient_phone(text),
      recipient_address: extract_recipient_address(text),
      courier_company: extract_courier_company(text),
      weight: extract_weight(text)
    }
  end

  def extract_tracking_number(text)
    patterns = [
      /SF\d{10,12}/,     # 顺丰
      /YT\d{10,12}/,     # 圆通
      /ZT\d{10,12}/,     # 中通
      /YD\d{10,12}/,     # 韵达
      /STO\d{10,12}/,    # 申通
      /JD\d{10,12}/,     # 京东
      /EMS\d{9,13}/,     # EMS
      /\d{12,14}/        # 通用数字格式
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[0] if match
    end

    nil
  end

  def extract_recipient_name(text)
    name_pattern = /[\u4e00-\u9fa5]{2,4}/
    matches = text.scan(name_pattern)

    # 通常姓名不会出现在开头（快递公司名称之后）
    return matches[1] if matches.size >= 2
    matches.first
  end

  def extract_recipient_phone(text)
    phone_pattern = /1[3-9]\d{9}/
    match = text.match(phone_pattern)
    match ? match[0] : nil
  end

  def extract_recipient_address(text)
    # 提取地址信息（包含省市区的文本）
    address_pattern = /([\u4e00-\u9fa5]{2,3}省|[\u4e00-\u9fa5]{2,3}市|[\u4e00-\u9fa5]{2,4}区)[\u4e00-\u9fa50-9路街号]+/
    match = text.match(address_pattern)
    match ? match[0] : nil
  end

  def extract_courier_company(text)
    companies = {
      '顺丰' => '顺丰速运',
      '圆通' => '圆通速递',
      '中通' => '中通快递',
      '韵达' => '韵达快递',
      '申通' => '申通快递',
      '京东' => '京东物流',
      'EMS' => 'EMS',
      '邮政' => '中国邮政',
      '天天' => '天天快递',
      '优速' => '优速快递',
      '全峰' => '全峰快递',
      '快捷' => '快捷快递'
    }

    companies.each do |keyword, name|
      return name if text.include?(keyword)
    end

    nil
  end

  def extract_weight(text)
    weight_pattern = /(\d+\.?\d*)\s*(kg|KG|公斤|g|G|克)/
    match = text.match(weight_pattern)
    match ? match[1] : nil
  end

  def calculate_confidence(raw_text, parsed_data)
    confidence = {}
    total_score = 0
    field_count = 0

    # 运单号置信度
    if parsed_data[:tracking_number]
      tracking_pattern = /#{Regexp.escape(parsed_data[:tracking_number])}/
      confidence[:tracking_number_confidence] = raw_text.match?(tracking_pattern) ? 95.0 : 70.0
      total_score += confidence[:tracking_number_confidence]
      field_count += 1
    else
      confidence[:tracking_number_confidence] = 0.0
    end

    # 收件人置信度
    if parsed_data[:recipient_name]
      name_pattern = /#{Regexp.escape(parsed_data[:recipient_name])}/
      confidence[:recipient_name_confidence] = raw_text.match?(name_pattern) ? 85.0 : 60.0
      total_score += confidence[:recipient_name_confidence]
      field_count += 1
    else
      confidence[:recipient_name_confidence] = 0.0
    end

    # 手机号置信度（格式验证）
    if parsed_data[:recipient_phone]
      confidence[:recipient_phone_confidence] = parsed_data[:recipient_phone].match?(/^1[3-9]\d{9}$/) ? 98.0 : 50.0
      total_score += confidence[:recipient_phone_confidence]
      field_count += 1
    else
      confidence[:recipient_phone_confidence] = 0.0
    end

    # 地址置信度
    if parsed_data[:recipient_address]
      confidence[:recipient_address_confidence] = 75.0
      total_score += confidence[:recipient_address_confidence]
      field_count += 1
    else
      confidence[:recipient_address_confidence] = 0.0
    end

    # 快递公司置信度
    if parsed_data[:courier_company]
      confidence[:courier_company_confidence] = 80.0
      total_score += confidence[:courier_company_confidence]
      field_count += 1
    else
      confidence[:courier_company_confidence] = 0.0
    end

    # 计算总体置信度
    confidence[:overall_confidence] = field_count > 0 ? (total_score / field_count).round(2) : 0.0

    confidence
  end
end
