# OCR验证器 - 负责识别结果的验证和校正
class OcrValidator
  # 验证和校正OCR识别结果
  def validate_and_correct(ocr_result)
    return ocr_result unless ocr_result[:success]

    data = ocr_result[:data]
    corrections = {}

    # 验证和校正运单号
    if data[:tracking_number].present?
      corrected_tracking = correct_tracking_number(data[:tracking_number])
      corrections[:tracking_number] = corrected_tracking if corrected_tracking != data[:tracking_number]
    end

    # 验证和校正手机号
    if data[:customer_phone].present?
      corrected_phone = correct_phone_number(data[:customer_phone])
      corrections[:customer_phone] = corrected_phone if corrected_phone != data[:customer_phone]
    end

    # 验证和校正姓名
    if data[:customer_name].present?
      corrected_name = correct_name(data[:customer_name])
      corrections[:customer_name] = corrected_name if corrected_name != data[:customer_name]
    end

    # 验证和校正地址
    if data[:recipient_address].present?
      corrected_address = correct_address(data[:recipient_address])
      corrections[:recipient_address] = corrected_address if corrected_address != data[:recipient_address]
    end

    # 如果有校正，更新结果
    if corrections.any?
      corrected_data = data.merge(corrections)
      {
        success: true,
        data: corrected_data,
        corrections: corrections,
        original_confidence: data[:confidence],
        corrected_confidence: recalculate_confidence(corrected_data)
      }
    else
      ocr_result
    end
  end

  # 最终验证
  def final_validation(ocr_result)
    return ocr_result unless ocr_result[:success]

    data = ocr_result[:data]
    validation_results = {}

    # 验证必填字段
    validation_results[:tracking_number] = validate_tracking_number(data[:tracking_number])
    validation_results[:customer_phone] = validate_phone_number(data[:customer_phone])
    validation_results[:customer_name] = validate_name(data[:customer_name])

    # 检查是否满足最低要求
    required_fields_valid = validation_results.values.all? { |result| result[:valid] }

    if required_fields_valid
      # 所有必填字段有效
      ocr_result.merge({
        validation: {
          passed: true,
          results: validation_results,
          score: calculate_validation_score(validation_results)
        }
      })
    else
      # 有字段验证失败
      {
        success: false,
        error: "识别结果验证失败",
        validation: {
          passed: false,
          results: validation_results,
          failed_fields: validation_results.select { |_, result| !result[:valid] }.keys
        }
      }
    end
  end

  # 验证运单号格式
  def validate_tracking_number(tracking_number)
    valid = tracking_number.present? && tracking_number.match?(/^[A-Za-z0-9]{10,20}$/)
    {
      valid: valid,
      message: valid ? "运单号格式正确" : "运单号格式不正确"
    }
  end

  # 验证手机号格式
  def validate_phone_number(phone_number)
    valid = phone_number.present? && phone_number.match?(/^1[3-9]\d{9}$/)
    {
      valid: valid,
      message: valid ? "手机号格式正确" : "手机号格式不正确"
    }
  end

  # 验证姓名格式
  def validate_name(name)
    valid = name.present? && name.match?(/^[\u4e00-\u9fa5]{2,4}$/)
    {
      valid: valid,
      message: valid ? "姓名格式正确" : "姓名格式不正确"
    }
  end

  # 校正运单号
  def correct_tracking_number(tracking_number)
    # 清理特殊字符和空格
    cleaned = tracking_number.gsub(/[^A-Za-z0-9]/, "")

    # 常见OCR错误校正
    corrections = {
      "O" => "0", "I" => "1", "Z" => "2", "S" => "5", "B" => "8"
    }

    corrected = cleaned.chars.map do |char|
      corrections[char] || char
    end.join

    corrected
  end

  # 校正手机号
  def correct_phone_number(phone_number)
    # 清理非数字字符
    cleaned = phone_number.gsub(/\D/, "")

    # 检查是否为11位手机号
    if cleaned.length == 11 && cleaned.start_with?("1")
      cleaned
    else
      # 尝试从文本中提取手机号
      extract_phone_number(phone_number) || cleaned
    end
  end

  # 校正姓名
  def correct_name(name)
    # 清理特殊字符和数字
    cleaned = name.gsub(/[^\u4e00-\u9fa5]/, "")

    # 常见OCR错误校正（汉字相似字符）
    corrections = {
      "王" => "王", "玉" => "王",  # 示例校正
      "李" => "李", "季" => "李"
    }

    corrected = cleaned.chars.map do |char|
      corrections[char] || char
    end.join

    corrected
  end

  # 校正地址
  def correct_address(address)
    # 地址标准化处理
    standardized = address
      .gsub(/\s+/, " ")  # 合并多个空格
      .gsub(/[，,]/, "，")  # 统一中文逗号
      .strip

    # 常见地址校正
    address_corrections = {
      "阜新" => "阜新市",
      "户纳" => "户纳镇"
    }

    address_corrections.each do |wrong, correct|
      standardized.gsub!(wrong, correct)
    end

    standardized
  end

  private

  # 从文本中提取手机号
  def extract_phone_number(text)
    # 使用正则表达式提取可能的手机号
    phone_patterns = [
      /1[3-9]\d{9}/,  # 标准手机号
      /\d{11}/,       # 11位数字
      /\d{3}-?\d{4}-?\d{4}/  # 带分隔符的手机号
    ]

    phone_patterns.each do |pattern|
      match = text.match(pattern)
      if match
        phone = match[0].gsub(/\D/, "")
        return phone if phone.length == 11 && phone.start_with?("1")
      end
    end

    nil
  end

  # 重新计算置信度
  def recalculate_confidence(data)
    base_confidence = data[:confidence].to_f

    # 根据字段验证结果调整置信度
    validation_factors = []

    if validate_tracking_number(data[:tracking_number])[:valid]
      validation_factors << 0.1
    end

    if validate_phone_number(data[:customer_phone])[:valid]
      validation_factors << 0.1
    end

    if validate_name(data[:customer_name])[:valid]
      validation_factors << 0.1
    end

    # 增加置信度（因为经过验证校正）
    adjusted_confidence = base_confidence + validation_factors.sum

    [ adjusted_confidence, 0.99 ].min.round(2)  # 不超过0.99
  end

  # 计算验证分数
  def calculate_validation_score(validation_results)
    total_fields = validation_results.size
    valid_fields = validation_results.count { |_, result| result[:valid] }

    (valid_fields.to_f / total_fields * 100).round(1)
  end
end
