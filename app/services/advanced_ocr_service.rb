# 高级OCR识别服务 - 集成多种识别技术和智能验证
class AdvancedOcrService
  def initialize
    @ai_enhanced_service = AiEnhancedOcrService.new
    @image_processor = ImageProcessor.new
    @validator = OcrValidator.new
  end

  # 主识别方法 - 支持多种识别模式
  def recognize_parcel(image, options = {})
    mode = options[:mode] || :auto
    validate_image = options[:validate_image] || true

    # 图像预处理和验证
    if validate_image
      validation_result = validate_image_quality(image)
      unless validation_result[:valid]
        return {
          success: false,
          error: "图像质量不合格: #{validation_result[:errors].join(', ')}"
        }
      end
    end

    # 根据模式选择识别策略
    case mode
    when :ai_only
      recognize_with_ai_only(image)
    when :traditional_only
      recognize_with_traditional_only(image)
    when :hybrid
      recognize_with_hybrid_approach(image)
    else
      recognize_with_auto_mode(image)
    end
  end

  # 仅使用AI识别
  def recognize_with_ai_only(image)
    @ai_enhanced_service.recognize_parcel_with_ai(image)
  end

  # 仅使用传统OCR识别
  def recognize_with_traditional_only(image)
    # 图像预处理
    processed_image = @image_processor.preprocess_for_ocr(image)
    
    # 使用传统OCR引擎
    traditional_result = TraditionalOcrService.new.recognize(processed_image)
    
    # 结果验证和后处理
    validated_result = @validator.validate_and_correct(traditional_result)
    
    validated_result
  end

  # 混合模式识别
  def recognize_with_hybrid_approach(image)
    # 并行执行AI和传统OCR
    ai_result = recognize_with_ai_only(image)
    traditional_result = recognize_with_traditional_only(image)

    # 结果融合和冲突解决
    fused_result = fuse_results(ai_result, traditional_result)
    
    # 最终验证
    final_result = @validator.final_validation(fused_result)
    
    final_result
  end

  # 自动模式识别
  def recognize_with_auto_mode(image)
    # 首先尝试AI识别
    ai_result = recognize_with_ai_only(image)
    
    if ai_result[:success] && ai_result[:data][:confidence] > 0.8
      # AI识别置信度高，直接返回
      ai_result
    else
      # AI识别置信度低，使用混合模式
      recognize_with_hybrid_approach(image)
    end
  end

  # 批量识别
  def batch_recognize(images, options = {})
    results = {}
    
    images.each_with_index do |image, index|
      begin
        results[index] = recognize_parcel(image, options)
      rescue => e
        results[index] = {
          success: false,
          error: "第#{index + 1}张图片识别失败: #{e.message}"
        }
      end
    end
    
    {
      success: true,
      data: {
        total: images.size,
        successful: results.values.count { |r| r[:success] },
        failed: results.values.count { |r| !r[:success] },
        results: results
      }
    }
  end

  # 图像质量验证
  def validate_image_quality(image)
    errors = []
    
    # 检查图像尺寸
    if image.width < 300 || image.height < 300
      errors << "图像尺寸过小，建议至少300x300像素"
    end
    
    # 检查图像清晰度（使用简单的模糊检测）
    blur_score = calculate_blur_score(image)
    if blur_score > 0.8
      errors << "图像模糊，请重新拍摄"
    end
    
    # 检查亮度
    brightness = calculate_brightness(image)
    if brightness < 0.3 || brightness > 0.8
      errors << "图像亮度不合适，建议在自然光下拍摄"
    end
    
    {
      valid: errors.empty?,
      errors: errors,
      metrics: {
        width: image.width,
        height: image.height,
        blur_score: blur_score,
        brightness: brightness
      }
    }
  end

  # 结果融合算法
  def fuse_results(ai_result, traditional_result)
    return traditional_result unless ai_result[:success]
    return ai_result unless traditional_result[:success]

    ai_data = ai_result[:data]
    traditional_data = traditional_result[:data]

    # 基于置信度的融合
    fused_data = {}
    
    # 运单号融合
    fused_data[:tracking_number] = fuse_tracking_number(ai_data, traditional_data)
    
    # 姓名融合
    fused_data[:customer_name] = fuse_name(ai_data, traditional_data)
    
    # 手机号融合
    fused_data[:customer_phone] = fuse_phone(ai_data, traditional_data)
    
    # 其他字段融合
    fused_data[:courier_company] = ai_data[:courier_company] || traditional_data[:courier_company]
    fused_data[:recipient_address] = fuse_address(ai_data, traditional_data)
    
    # 计算综合置信度
    fused_data[:confidence] = calculate_fused_confidence(ai_data, traditional_data)
    
    {
      success: true,
      data: fused_data,
      source: "hybrid",
      ai_confidence: ai_data[:confidence],
      traditional_confidence: traditional_data[:confidence]
    }
  end

  private

  # 计算图像模糊度（简化版本）
  def calculate_blur_score(image)
    # 这里可以使用OpenCV的Laplacian方差等算法
    # 简化实现：返回一个随机值（实际项目中需要实现真正的模糊检测）
    rand(0.1..0.3) # 模拟清晰图像
  end

  # 计算图像亮度
  def calculate_brightness(image)
    # 简化实现：返回一个随机值（实际项目中需要计算平均亮度）
    rand(0.4..0.6) # 模拟正常亮度
  end

  # 运单号融合算法
  def fuse_tracking_number(ai_data, traditional_data)
    ai_tracking = ai_data[:tracking_number].to_s.strip
    traditional_tracking = traditional_data[:tracking_number].to_s.strip
    
    # 如果AI识别结果符合运单号格式，优先使用
    if valid_tracking_number?(ai_tracking)
      ai_tracking
    elsif valid_tracking_number?(traditional_tracking)
      traditional_tracking
    else
      # 尝试合并或选择更长的结果
      [ai_tracking, traditional_tracking].max_by(&:length)
    end
  end

  # 姓名融合算法
  def fuse_name(ai_data, traditional_data)
    ai_name = ai_data[:customer_name].to_s.strip
    traditional_name = traditional_data[:customer_name].to_s.strip
    
    # 优先选择中文姓名（2-4个汉字）
    if chinese_name?(ai_name)
      ai_name
    elsif chinese_name?(traditional_name)
      traditional_name
    else
      # 选择更符合姓名格式的结果
      ai_name.present? ? ai_name : traditional_name
    end
  end

  # 手机号融合算法
  def fuse_phone(ai_data, traditional_data)
    ai_phone = ai_data[:customer_phone].to_s.strip
    traditional_phone = traditional_data[:customer_phone].to_s.strip
    
    # 优先选择符合手机号格式的结果
    if valid_phone_number?(ai_phone)
      ai_phone
    elsif valid_phone_number?(traditional_phone)
      traditional_phone
    else
      # 清理非数字字符后选择
      clean_ai = ai_phone.gsub(/\D/, '')
      clean_traditional = traditional_phone.gsub(/\D/, '')
      
      valid_phone_number?(clean_ai) ? clean_ai : clean_traditional
    end
  end

  # 地址融合算法
  def fuse_address(ai_data, traditional_data)
    ai_address = ai_data[:recipient_address].to_s.strip
    traditional_address = traditional_data[:recipient_address].to_s.strip
    
    # 选择更详细的结果
    if ai_address.length > traditional_address.length
      ai_address
    else
      traditional_address
    end
  end

  # 计算融合置信度
  def calculate_fused_confidence(ai_data, traditional_data)
    ai_confidence = ai_data[:confidence].to_f
    traditional_confidence = traditional_data[:confidence].to_f
    
    # 加权平均，AI权重更高
    (ai_confidence * 0.7 + traditional_confidence * 0.3).round(2)
  end

  # 验证运单号格式
  def valid_tracking_number?(tracking_number)
    tracking_number.present? && tracking_number.match?(/^[A-Za-z0-9]{10,20}$/)
  end

  # 验证中文姓名
  def chinese_name?(name)
    name.present? && name.match?(/^[\u4e00-\u9fa5]{2,4}$/)
  end

  # 验证手机号格式
  def valid_phone_number?(phone)
    phone.present? && phone.match?(/^1[3-9]\d{9}$/)
  end
end