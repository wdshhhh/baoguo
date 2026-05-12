require "rtesseract"

class OcrEngine
  # OCR配置
  DEFAULT_OPTIONS = {
    lang: "chi_sim+eng",           # 中英文识别
    whitelist: nil,                 # 不限制字符白名单，允许识别中文
    psm: 3,                        # 自动页面分割模式
    confidence_threshold: 70,       # 置信度阈值
    enable_preprocessing: true      # 是否启用预处理
  }.freeze

  # Tesseract页面分割模式
  PSM_MODES = {
    auto: 3,           # 自动页面分割（默认）
    single_column: 4,  # 单列文本
    single_block: 5,   # 单个统一文本块
    single_line: 7,    # 单行文本
    single_word: 8,    # 单个词
    single_char: 10    # 单个字符
  }.freeze

  def initialize(options = {})
    @options = DEFAULT_OPTIONS.merge(options)
  end

  # 识别图像
  def recognize(image_path)
    # 预处理图像
    processed_path = if @options[:enable_preprocessing]
                       ImagePreprocessor.process(image_path, enable_preprocessing: true)
    else
                       image_path
    end

    begin
      # 配置Tesseract
      tesseract = RTesseract.new(processed_path, {
        lang: @options[:lang],
        psm: @options[:psm],
        whitelist: @options[:whitelist]
      })

      # 执行识别
      full_text = tesseract.to_s

      # 获取置信度信息
      confidence = get_confidence(tesseract, processed_path)

      # 解析识别结果
      result = parse_result(full_text, confidence)

      {
        success: true,
        text: full_text,
        result: result,
        confidence: confidence,
        processed: @options[:enable_preprocessing]
      }
    ensure
      # 清理临时文件
      if processed_path != image_path && File.exist?(processed_path)
        File.delete(processed_path)
      end
    end
  rescue StandardError => e
    Rails.logger.error "OCR识别失败: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  # 获取置信度（使用Tesseract的hocr输出）
  def get_confidence(tesseract, image_path)
    begin
      # 使用命令行获取详细的置信度信息
      command = "tesseract #{Shellwords.escape(image_path)} stdout -l #{@options[:lang]} --psm #{@options[:psm]} -c tessedit_char_whitelist=#{Shellwords.escape(@options[:whitelist])} hocr"
      output = `#{command}`

      # 解析HOCR格式获取置信度
      confidence_scores = []
      output.scan(/title=".*?x_wconf (\d+)"/).each do |match|
        confidence_scores << match[0].to_i
      end

      if confidence_scores.any?
        {
          average: confidence_scores.sum.to_f / confidence_scores.size,
          min: confidence_scores.min,
          max: confidence_scores.max,
          details: confidence_scores
        }
      else
        {
          average: 80,  # 默认置信度
          min: 70,
          max: 90,
          details: []
        }
      end
    rescue StandardError
      {
        average: 75,
        min: 60,
        max: 90,
        details: []
      }
    end
  end

  # 解析识别结果
  def parse_result(text, confidence)
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    result = {
      tracking_number: extract_tracking_number(lines),
      recipient_name: extract_name(lines),
      recipient_phone: extract_phone(lines),
      courier_company: extract_courier(lines),
      address: extract_address(lines),
      raw_lines: lines
    }

    # 添加字段级置信度
    result[:confidence] = calculate_field_confidence(result, confidence)

    result
  end

  # 提取运单号
  def extract_tracking_number(lines)
    # 运单号模式：2位字母前缀 + 8-16位数字
    tracking_pattern = /([A-Z]{2}[0-9]{8,16})/

    lines.each do |line|
      match = line.match(tracking_pattern)
      return match[1] if match
    end

    # 尝试提取纯数字（可能没有字母前缀）
    lines.each do |line|
      match = line.match(/([0-9]{10,18})/)
      return match[1] if match
    end

    nil
  end

  # 提取姓名
  def extract_name(lines)
    # 常见姓名关键词
    name_keywords = [ "姓名", "收件人", "收货人", "寄件人", "联系人", "To:", "Name:" ]

    lines.each do |line|
      name_keywords.each do |keyword|
        if line.include?(keyword)
          # 提取关键词后面的内容
          parts = line.split(keyword)
          if parts.size > 1
            name = parts[1].strip.gsub(/[^\u4e00-\u9fa5a-zA-Z]/, "")
            return name if name.size >= 2 && name.size <= 20
          end
        end
      end
    end

    # 尝试直接提取中文字符串（2-20个汉字）
    lines.each do |line|
      match = line.match(/([\u4e00-\u9fa5]{2,20})/)
      return match[1] if match
    end

    nil
  end

  # 提取手机号
  def extract_phone(lines)
    # 手机号模式：1开头的11位数字
    phone_pattern = /(1[3-9][0-9]{9})/

    lines.each do |line|
      # 去除空格和特殊字符
      clean_line = line.gsub(/[\s\-()]/, "")
      match = clean_line.match(phone_pattern)
      return match[1] if match
    end

    nil
  end

  # 提取快递公司
  def extract_courier(lines)
    courier_keywords = {
      "顺丰" => "顺丰速运",
      "中通" => "中通快递",
      "圆通" => "圆通速递",
      "申通" => "申通快递",
      "韵达" => "韵达快递",
      "EMS" => "EMS",
      "京东" => "京东物流",
      "天天" => "天天快递",
      "全峰" => "全峰快递",
      "国通" => "国通快递",
      "宅急送" => "宅急送",
      "SF" => "顺丰速运",
      "ZT" => "中通快递",
      "YT" => "圆通速递",
      "ST" => "申通快递",
      "YD" => "韵达快递",
      "JD" => "京东物流"
    }

    lines.each do |line|
      courier_keywords.each do |keyword, company|
        if line.include?(keyword)
          return company
        end
      end
    end

    nil
  end

  # 提取地址
  def extract_address(lines)
    address_keywords = [ "省", "市", "区", "路", "街", "巷", "号", "小区", "大厦", "公寓", "楼", "室" ]

    tracking_number = extract_tracking_number(lines)
    recipient_name = extract_name(lines)
    recipient_phone = extract_phone(lines)

    address_lines = []

    lines.each do |line|
      next if line.empty?

      # 跳过包含运单号、姓名、电话的行
      next if tracking_number && line.include?(tracking_number)
      next if recipient_name && line.include?(recipient_name)
      next if recipient_phone && line.include?(recipient_phone)

      # 跳过快递公司名称
      next if line =~ /顺丰|中通|圆通|申通|韵达|EMS|京东/

      # 跳过纯数字或纯字母的行（这些通常不是地址）
      next if line =~ /^[0-9]+$/ || line =~ /^[A-Za-z]+$/

      # 检查是否包含地址关键词
      if address_keywords.any? { |kw| line.include?(kw) }
        address_lines << line
      end
    end

    # 如果找到地址行，返回合并后的地址
    if address_lines.any?
      address_lines.join(" ").strip
    else
      # 尝试从所有非空行中提取可能的地址信息
      candidate_lines = lines.reject do |line|
        line.empty? ||
        (tracking_number && line.include?(tracking_number)) ||
        (recipient_phone && line.include?(recipient_phone)) ||
        line =~ /^[0-9]+$/ ||
        line =~ /^[A-Za-z]+$/ ||
        line =~ /顺丰|中通|圆通|申通|韵达|EMS|京东|姓名|电话|运单号/
      end

      # 如果还有候选行，取最长的作为地址
      if candidate_lines.any?
        candidate_lines.max_by { |l| l.length }.strip
      else
        nil
      end
    end
  end

  # 计算字段级置信度
  def calculate_field_confidence(result, overall_confidence)
    base_confidence = overall_confidence[:average] || 75

    {
      tracking_number: result[:tracking_number] ? base_confidence : 0,
      recipient_name: result[:recipient_name] ? base_confidence : 0,
      recipient_phone: result[:recipient_phone] ? base_confidence : 0,
      courier_company: result[:courier_company] ? base_confidence : 0,
      overall: base_confidence
    }
  end

  # 类方法：快速识别
  def self.recognize(image_path, options = {})
    new(options).recognize(image_path)
  end
end
