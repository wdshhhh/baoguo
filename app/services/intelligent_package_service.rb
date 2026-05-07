class IntelligentPackageService
  def initialize
    @deepseek_service = DeepseekApiService.new(ENV["DEEPSEEK_API_KEY"])
  end

  # 智能包裹分类
  def classify_package(ocr_data)
    begin
      # 使用DeepSeek API进行智能分类
      ocr_text = ocr_data[:raw_text] || ocr_data.to_s
      result = @deepseek_service.intelligent_package_classification(ocr_text)

      if result[:success]
        {
          success: true,
          data: result[:data]
        }
      else
        # 如果API调用失败，回退到规则引擎
        fallback_result = analyze_package_characteristics(ocr_data)
        {
          success: true,
          data: {
            package_type: fallback_result[:package_type],
            priority_level: fallback_result[:priority_level],
            estimated_weight: fallback_result[:estimated_weight],
            special_handling: fallback_result[:special_handling],
            confidence: fallback_result[:confidence] * 0.8,  # 降低置信度
            reasoning: "使用规则引擎分类（API调用失败）"
          }
        }
      end
    rescue => e
      {
        success: false,
        error: "智能分类失败: #{e.message}"
      }
    end
  end

  # 包裹特征分析
  def analyze_package_characteristics(ocr_data)
    text = ocr_data[:raw_text] || ""
    tracking_number = ocr_data[:tracking_number] || ""

    # 包裹类型分类
    package_type = classify_package_type(text, tracking_number)

    # 优先级评估
    priority_level = assess_priority_level(tracking_number, package_type)

    # 重量估算
    estimated_weight = estimate_weight(text)

    # 特殊处理需求
    special_handling = identify_special_handling(text)

    {
      package_type: package_type,
      priority_level: priority_level,
      estimated_weight: estimated_weight,
      special_handling: special_handling,
      confidence: calculate_confidence(text)
    }
  end

  # 包裹类型分类
  def classify_package_type(text, tracking_number)
    text = text.downcase

    # 基于关键词和运单号特征分类
    if text.include?("易碎") || text.include?("fragile")
      "fragile"
    elsif text.include?("大件") || text.include?("large") || estimated_size_large?(text)
      "large"
    elsif tracking_number.start_with?("SF")  # 顺丰通常为重要包裹
      "priority"
    elsif text.include?("文件") || text.include?("document")
      "document"
    else
      "normal"
    end
  end

  # 优先级评估
  def assess_priority_level(tracking_number, package_type)
    case package_type
    when "fragile", "priority"
      "high"
    when "large"
      "medium"
    else
      "normal"
    end
  end

  # 重量估算
  def estimate_weight(text)
    # 从文本中提取重量信息
    weight_patterns = [
      /(\d+\.?\d*)\s*kg/i,
      /(\d+\.?\d*)\s*千克/i,
      /重量[：:]\s*(\d+\.?\d*)/i
    ]

    weight_patterns.each do |pattern|
      match = text.match(pattern)
      return match[1].to_f if match
    end

    # 默认重量估算
    default_weight = 1.5
    default_weight
  end

  # 特殊处理需求识别
  def identify_special_handling(text)
    special_handling = []

    if text.include?("易碎") || text.include?("fragile")
      special_handling << "fragile_handling"
    end

    if text.include?("冷藏") || text.include?("refrigerated")
      special_handling << "temperature_control"
    end

    if text.include?("贵重") || text.include?("valuable")
      special_handling << "valuable_handling"
    end

    special_handling
  end

  # 估算包裹尺寸是否为大件
  def estimated_size_large?(text)
    large_keywords = [ "大件", "large", "重型", "heavy", "体积大" ]
    large_keywords.any? { |keyword| text.include?(keyword) }
  end

  # 计算分类置信度
  def calculate_confidence(text)
    # 基于文本长度和关键词匹配度计算置信度
    base_confidence = 0.7

    # 关键词匹配加分
    keywords = [ "kg", "千克", "重量", "fragile", "易碎", "大件", "large" ]
    keyword_matches = keywords.count { |keyword| text.include?(keyword) }

    confidence = base_confidence + (keyword_matches * 0.05)
    [ confidence, 0.95 ].min  # 最大置信度95%
  end

  # 批量包裹智能排序
  def intelligent_sorting(packages)
    packages.sort_by do |package|
      priority_score = calculate_priority_score(package)
      [ -priority_score, package.created_at ]  # 优先级高的在前，时间早的在前
    end
  end

  # 计算包裹优先级分数
  def calculate_priority_score(package)
    score = 0

    # 包裹类型加分
    case package.package_type
    when "fragile"
      score += 30
    when "priority"
      score += 20
    when "large"
      score += 10
    end

    # 等待时间加分（等待时间越长，优先级越高）
    wait_time = (Time.current - package.created_at).to_i / 3600  # 小时
    score += [ wait_time * 2, 50 ].min  # 最大加分50

    score
  end
end
