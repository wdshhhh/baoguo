class OcrPostProcessor
  # 常见字符混淆映射（OCR识别时容易混淆的字符）
  CHARACTER_CONFUSIONS = {
    'O' => '0', 'o' => '0',
    'I' => '1', 'i' => '1', 'l' => '1', 'L' => '1',
    'Z' => '2', 'z' => '2',
    'S' => '5', 's' => '5',
    'B' => '8',
    'G' => '6', 'g' => '6',
    'D' => '0', 'd' => '0',
    'Q' => '0', 'q' => '0',
    'R' => '8', 'r' => '8'
  }.freeze

  # 运单号前缀与快递公司映射
  TRACKING_PREFIX_MAP = {
    'SF' => '顺丰速运',
    'ZT' => '中通快递',
    'YT' => '圆通速递',
    'ST' => '申通快递',
    'YD' => '韵达快递',
    'JD' => '京东物流',
    'EMS' => 'EMS',
    'DN' => '德邦快递',
    'YZ' => '邮政快递'
  }.freeze

  # 快递公司关键词
  COURIER_KEYWORDS = {
    '顺丰速运' => ['顺丰', 'SF', '顺丰速运'],
    '中通快递' => ['中通', 'ZT', '中通快递'],
    '圆通速递' => ['圆通', 'YT', '圆通速递'],
    '申通快递' => ['申通', 'ST', '申通快递'],
    '韵达快递' => ['韵达', 'YD', '韵达快递'],
    'EMS' => ['EMS', '邮政', '中国邮政'],
    '京东物流' => ['京东', 'JD', '京东物流'],
    '天天快递' => ['天天', 'TT'],
    '全峰快递' => ['全峰', 'QF'],
    '国通快递' => ['国通', 'GT'],
    '宅急送' => ['宅急送', 'ZJS']
  }.freeze

  def initialize(ocr_result)
    @result = ocr_result
    @corrections = {}
    @suggestions = []
  end

  # 执行完整的后处理流程
  def process
    # 1. 运单号校验和纠错
    @result[:tracking_number] = correct_tracking_number(@result[:tracking_number])

    # 2. 手机号提取和验证
    @result[:recipient_phone] = correct_phone(@result[:recipient_phone])

    # 3. 姓名验证和清理
    @result[:recipient_name] = clean_name(@result[:recipient_name])

    # 4. 快递公司匹配
    @result[:courier_company] = match_courier_company(@result[:courier_company], @result[:tracking_number])

    # 5. 验证运单号与快递公司匹配
    validate_tracking_courier_match

    # 6. 生成质量评估
    @result[:quality] = evaluate_quality

    {
      result: @result,
      corrections: @corrections,
      suggestions: @suggestions
    }
  end

  # 运单号纠错
  def correct_tracking_number(tracking_number)
    return nil unless tracking_number.present?

    original = tracking_number.dup
    corrected = tracking_number.upcase.strip

    # 去除非字母数字字符
    corrected = corrected.gsub(/[^A-Z0-9]/, '')

    # 字符混淆替换（只替换数字部分，保留字母前缀）
    prefix = corrected.match(/^([A-Z]{0,3})/) ? corrected.match(/^([A-Z]{0,3})/)[1] : ''
    number_part = corrected[prefix.length..-1] || ''
    
    # 对数字部分进行字符混淆替换
    number_part.each_char.with_index do |char, index|
      if CHARACTER_CONFUSIONS.key?(char)
        number_part[index] = CHARACTER_CONFUSIONS[char]
        @corrections[:tracking_number] = corrected if corrected != original
      end
    end

    corrected = prefix + number_part

    # 确保运单号长度在10-20位之间
    if corrected.length < 10
      @suggestions << "运单号长度过短（#{corrected.length}位），请检查是否完整"
    elsif corrected.length > 20
      corrected = corrected[0..19]
      @corrections[:tracking_number] = corrected if corrected != original
    end

    corrected.empty? ? nil : corrected
  end

  # 手机号验证和纠错
  def correct_phone(phone)
    return nil unless phone.present?

    original = phone.dup
    corrected = phone.gsub(/\D/, '')

    # 如果是10位且以3-9开头，可能漏掉了开头的1
    if corrected.length == 10 && corrected =~ /^[3-9]/
      corrected = '1' + corrected
      @corrections[:recipient_phone] = corrected if corrected != original
      @suggestions << "手机号自动补充前缀'1'"
    end

    # 如果是12位且以86开头，去掉国际区号
    if corrected.length == 12 && corrected.start_with?('86')
      corrected = corrected[2..11]
      @corrections[:recipient_phone] = corrected if corrected != original
    end

    # 验证11位手机号格式
    if corrected.length == 11
      if corrected.start_with?('1') && corrected[1] =~ /[3-9]/
        # 格式正确
      else
        @suggestions << "手机号格式不正确，请检查"
      end
    elsif corrected.length != 0
      @suggestions << "手机号长度异常（#{corrected.length}位）"
    end

    corrected.length == 11 ? corrected : nil
  end

  # 姓名清理
  def clean_name(name)
    return nil unless name.present?

    # 去除非法字符，只保留中文、英文和数字
    cleaned = name.gsub(/[^\u4e00-\u9fa5a-zA-Z0-9]/, '').strip

    # 确保长度在2-20个字符之间
    if cleaned.length < 2
      @suggestions << "姓名长度过短，请检查"
      return nil
    elsif cleaned.length > 20
      cleaned = cleaned[0..19]
    end

    cleaned.empty? ? nil : cleaned
  end

  # 快递公司匹配
  def match_courier_company(courier, tracking_number)
    # 如果已经有快递公司，先验证
    if courier.present?
      normalized_courier = normalize_courier(courier)
      return normalized_courier if normalized_courier
    end

    # 根据运单号前缀推断快递公司
    if tracking_number.present?
      prefix = tracking_number.upcase[0..1]
      if TRACKING_PREFIX_MAP.key?(prefix)
        inferred_courier = TRACKING_PREFIX_MAP[prefix]
        @suggestions << "根据运单号前缀自动推断快递公司为#{inferred_courier}" unless courier.present?
        return inferred_courier
      end
    end

    nil
  end

  # 规范化快递公司名称
  def normalize_courier(courier)
    COURIER_KEYWORDS.each do |standard_name, keywords|
      keywords.each do |keyword|
        if courier.include?(keyword)
          return standard_name
        end
      end
    end
    nil
  end

  # 验证运单号与快递公司匹配
  def validate_tracking_courier_match
    return unless @result[:tracking_number].present? && @result[:courier_company].present?

    prefix = @result[:tracking_number].upcase[0..1]
    
    if TRACKING_PREFIX_MAP.key?(prefix)
      expected_courier = TRACKING_PREFIX_MAP[prefix]
      if @result[:courier_company] != expected_courier
        @suggestions << "运单号前缀#{prefix}通常对应#{expected_courier}，但当前识别为#{@result[:courier_company]}，请确认"
        # 自动纠正
        @result[:courier_company] = expected_courier
        @corrections[:courier_company] = expected_courier
      end
    end
  end

  # 质量评估
  def evaluate_quality
    score = 0
    details = []

    # 运单号质量
    if @result[:tracking_number].present?
      if @result[:tracking_number].length >= 12 && @result[:tracking_number].length <= 18
        score += 25
        details << { field: '运单号', status: 'good', comment: '长度符合要求' }
      else
        details << { field: '运单号', status: 'warning', comment: '长度异常' }
      end
      if @result[:tracking_number] =~ /^[A-Z]{2}[0-9]+$/
        score += 10
        details << { field: '运单号格式', status: 'good', comment: '格式正确' }
      end
    else
      details << { field: '运单号', status: 'error', comment: '缺失' }
    end

    # 姓名质量
    if @result[:recipient_name].present?
      if @result[:recipient_name].length >= 2 && @result[:recipient_name].length <= 20
        score += 25
        details << { field: '收件人', status: 'good', comment: '格式正确' }
      end
    else
      details << { field: '收件人', status: 'error', comment: '缺失' }
    end

    # 手机号质量
    if @result[:recipient_phone].present?
      if @result[:recipient_phone].length == 11 && @result[:recipient_phone] =~ /^1[3-9]\d{9}$/
        score += 30
        details << { field: '手机号', status: 'good', comment: '格式正确' }
      else
        details << { field: '手机号', status: 'warning', comment: '格式可能有误' }
      end
    else
      details << { field: '手机号', status: 'error', comment: '缺失' }
    end

    # 快递公司质量
    if @result[:courier_company].present?
      score += 10
      details << { field: '快递公司', status: 'good', comment: '已识别' }
    else
      details << { field: '快递公司', status: 'warning', comment: '未识别' }
    end

    level = if score >= 90
              'excellent'
            elsif score >= 70
              'good'
            elsif score >= 50
              'medium'
            else
              'poor'
            end

    {
      score: score,
      level: level,
      details: details
    }
  end

  # 类方法：快速处理
  def self.process(ocr_result)
    new(ocr_result).process
  end
end
