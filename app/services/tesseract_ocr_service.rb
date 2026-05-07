class TesseractOcrService
  def initialize
    # 不需要预先初始化，在识别时再创建
  end

  # 使用Tesseract进行OCR识别
  def recognize_parcel(image)
    begin
      # 保存临时文件
      temp_file_path = save_temp_image(image)

      # 使用最可靠的OCR服务进行识别
      reliable_ocr_service = ReliableOcrService.new(temp_file_path)
      ocr_result = reliable_ocr_service.recognize

      # 处理OCR识别结果
      if ocr_result[:success]
        # 从OCR文本中提取关键信息
        extracted_data = extract_parcel_info(ocr_result[:raw_text] || ocr_result[:text])

        {
          success: true,
          data: {
            tracking_number: extracted_data[:tracking_number],
            recipient_name: extracted_data[:recipient_name],
            recipient_phone: extracted_data[:recipient_phone],
            courier_company: extracted_data[:courier_company],
            recipient_address: extracted_data[:recipient_address],
            confidence: ocr_result[:confidence] || 0.5,
            raw_text: ocr_result[:raw_text] || ocr_result[:text] || ""
          }
        }
      else
        # OCR识别失败
        {
          success: false,
          data: {
            tracking_number: "",
            recipient_name: "",
            recipient_phone: "",
            courier_company: "",
            recipient_address: "",
            confidence: 0.1,
            raw_text: "OCR识别失败: #{ocr_result[:error]}"
          },
          error: ocr_result[:error] || "OCR识别失败"
        }
      end

    rescue => e
      Rails.logger.error("Tesseract OCR识别失败: #{e.message}")
      {
        success: false,
        data: {
          tracking_number: "",
          recipient_name: "",
          recipient_phone: "",
          courier_company: "",
          recipient_address: "",
          confidence: 0.1,
          raw_text: "OCR识别异常: #{e.message}"
        },
        error: "Tesseract OCR识别失败: #{e.message}"
      }
    ensure
      # 清理临时文件
      File.delete(temp_file_path) if temp_file_path && File.exist?(temp_file_path)
    end
  end

  private

  # 保存临时图片文件
  def save_temp_image(image)
    temp_dir = Rails.root.join("tmp", "ocr_uploads")
    FileUtils.mkdir_p(temp_dir)

    temp_filename = "ocr_#{SecureRandom.uuid}_#{image.original_filename}"
    temp_file_path = temp_dir.join(temp_filename)

    File.open(temp_file_path, "wb") do |file|
      file.write(image.read)
    end

    temp_file_path.to_s
  end

  # 从OCR文本中提取快递面单信息
  def extract_parcel_info(text)
    # 检查文本是否为nil或空
    if text.nil? || text.empty?
      return {
        tracking_number: "",
        recipient_name: "",
        recipient_phone: "",
        courier_company: "",
        recipient_address: ""
      }
    end

    # 简单的规则提取快递面单信息
    tracking_number = extract_tracking_number(text)
    phone_number = extract_phone_number(text)
    courier_company = extract_courier_company(text)

    {
      tracking_number: tracking_number,
      recipient_name: "",  # 姓名需要更复杂的识别，暂时留空
      recipient_phone: phone_number,
      courier_company: courier_company,
      recipient_address: ""  # 地址需要更复杂的识别，暂时留空
    }
  end

  # 提取运单号
  def extract_tracking_number(text)
    # 运单号通常是10-15位的数字或字母组合
    patterns = [
      /[A-Z]{2}\d{8,12}/,  # 如YD1234567890
      /\d{10,15}/,         # 纯数字运单号
      /SF\d{10,13}/,       # 顺丰运单号
      /YT\d{10,13}/,       # 圆通运单号
      /ZT\d{10,13}/,       # 中通运单号
      /STO\d{10,13}/       # 申通运单号
    ]

    patterns.each do |pattern|
      match = text.scan(pattern).first
      return match if match
    end

    ""
  end

  # 提取手机号
  def extract_phone_number(text)
    # 11位手机号
    phone_pattern = /1[3-9]\d{9}/
    match = text.scan(phone_pattern).first
    match || ""
  end

  # 提取快递公司
  def extract_courier_company(text)
    courier_companies = {
      "顺丰" => "顺丰",
      "圆通" => "圆通",
      "中通" => "中通",
      "申通" => "申通",
      "韵达" => "韵达",
      "邮政" => "邮政",
      "京东" => "京东",
      "德邦" => "德邦",
      "SF" => "顺丰",
      "YD" => "韵达",
      "YT" => "圆通",
      "ZT" => "中通",
      "STO" => "申通"
    }

    courier_companies.each do |keyword, company|
      return company if text.include?(keyword)
    end

    # 根据运单号前缀判断
    tracking_number = extract_tracking_number(text)
    if tracking_number.start_with?("SF")
      "顺丰"
    elsif tracking_number.start_with?("YD")
      "韵达"
    elsif tracking_number.start_with?("YT")
      "圆通"
    elsif tracking_number.start_with?("ZT")
      "中通"
    elsif tracking_number.start_with?("STO")
      "申通"
    else
      ""
    end
  end
end
