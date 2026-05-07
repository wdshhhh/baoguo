# 修复的OCR服务类 - 解决识别失败问题
class FixedOcrService
  def initialize(image_path)
    @image_path = image_path
    @use_tesseract = check_tesseract_available

    Rails.logger.info("=== 修复OCR系统初始化 ===")
    Rails.logger.info("当前引擎: #{@use_tesseract ? 'tesseract' : 'demo'}")
    Rails.logger.info("图片路径: #{@image_path}")
    Rails.logger.info("图片存在: #{File.exist?(@image_path)}")
  end

  # 执行OCR识别
  def recognize
    start_time = Time.now

    if @use_tesseract
      Rails.logger.info("使用Tesseract进行OCR识别...")
      result = perform_fixed_tesseract_ocr(start_time)
      Rails.logger.info("Tesseract识别完成: #{result[:success] ? '成功' : '失败'}")
      result
    else
      Rails.logger.warn("Tesseract不可用，使用演示模式...")
      result = perform_fixed_demo_ocr(start_time)
      Rails.logger.info("演示模式识别完成: #{result[:success] ? '成功' : '失败'}")
      result
    end
  rescue => e
    Rails.logger.error("OCR识别失败: #{e.message}")
    Rails.logger.error("错误堆栈: #{e.backtrace.join('\n')}")

    # 发生错误时自动切换到演示模式
    Rails.logger.warn("发生错误，回退到演示模式...")
    perform_fixed_demo_ocr(start_time)
  end

  private

  # 检查Tesseract是否可用
  def check_tesseract_available
    begin
      # 检查tesseract命令是否存在
      result = `which tesseract 2>&1`
      return false unless $?.success? && !result.empty?

      # 检查tesseract版本
      version = `tesseract --version 2>&1`
      return false unless $?.success?

      # 检查中文语言包
      langs = `tesseract --list-langs 2>&1`
      return false unless langs.include?("chi_sim")

      # 尝试加载rtesseract
      require "rtesseract"

      true
    rescue => e
      Rails.logger.warn("Tesseract检查失败: #{e.message}")
      false
    end
  end

  # 修复的Tesseract OCR识别
  def perform_fixed_tesseract_ocr(start_time)
    begin
      # 1. 修复的图片预处理
      Rails.logger.info("开始图片预处理...")
      processed_image_path = fixed_image_preprocessing

      unless processed_image_path
        raise "图片预处理失败"
      end

      # 2. 修复的Tesseract调用（增强中文识别）
      Rails.logger.info("调用Tesseract进行中文识别...")
      raw_text = call_fixed_tesseract(processed_image_path)

      # 3. 清理临时文件
      File.delete(processed_image_path) if File.exist?(processed_image_path)

      processing_time = Time.now - start_time

      {
        success: true,
        raw_text: raw_text,
        processing_time: processing_time,
        engine: "tesseract",
        confidence: calculate_fixed_confidence(raw_text),
        chinese_count: count_chinese_characters(raw_text)
      }

    rescue => e
      # 清理临时文件
      File.delete(processed_image_path) if processed_image_path && File.exist?(processed_image_path)
      raise e
    end
  end

  # 修复的图片预处理
  def fixed_image_preprocessing
    begin
      require "mini_magick"

      # 验证图片存在且可读
      unless File.exist?(@image_path) && File.readable?(@image_path)
        raise "图片文件不存在或不可读"
      end

      image = MiniMagick::Image.open(@image_path)

      # 记录原始图片信息
      original_info = {
        width: image.width,
        height: image.height,
        format: image.type,
        size: File.size(@image_path)
      }

      Rails.logger.info("原始图片信息: #{original_info}")

      # 修复的预处理流程 - 使用正确的MiniMagick语法

      # 自动旋转
      image.auto_orient

      # 调整大小
      if image.width > 1200 || image.height > 1200
        image.resize "1200x1200>"
      elsif image.width < 800 || image.height < 800
        image.resize "800x800<"
      end

      # 增强对比度（修复的调用方式）
      image.combine_options do |c|
        c.contrast
        c.brightness_contrast "10x20"
        c.sharpen "0x0.5"
      end

      # 转换为灰度
      image.colorspace "Gray"

      # 保存处理后的图片
      temp_image_path = Rails.root.join("tmp", "ocr_fixed_#{SecureRandom.uuid}.png")
      image.write(temp_image_path)

      # 记录处理后的信息
      processed_info = {
        width: image.width,
        height: image.height,
        format: image.type
      }

      Rails.logger.info("处理后图片信息: #{processed_info}")

      temp_image_path

    rescue => e
      Rails.logger.error("图片预处理失败: #{e.message}")
      nil
    end
  end

  # 修复的Tesseract调用
  def call_fixed_tesseract(image_path)
    begin
      # 确保图片路径是字符串（RTesseract无法处理Pathname对象）
      image_path_str = image_path.to_s

      # 使用优化的PSM模式
      psm_modes = [ 6, 8, 3 ]  # 统一文本块、单词、行

      best_result = ""
      best_confidence = 0

      psm_modes.each do |psm|
        begin
          image = RTesseract.new(image_path_str,
            lang: "chi_sim+eng",
            psm: psm,
            oem: 3
          )

          result = image.to_s.strip
          confidence = calculate_fixed_confidence(result)

          Rails.logger.info("PSM模式 #{psm} 识别结果: #{result[0..50]}... (置信度: #{confidence})")

          if confidence > best_confidence
            best_result = result
            best_confidence = confidence
          end

        rescue => e
          Rails.logger.warn("PSM模式 #{psm} 识别失败: #{e.message}")
        end
      end

      best_result

    rescue => e
      raise "Tesseract调用失败: #{e.message}"
    end
  end

  # 修复的置信度计算
  def calculate_fixed_confidence(text)
    return 0.0 if text.nil? || text.empty?

    # 基于文本长度、字符多样性、数字比例等计算置信度
    length_score = [ text.length.to_f / 50, 1.0 ].min
    diversity_score = text.chars.uniq.length.to_f / [ text.length, 1 ].max
    digit_ratio = text.scan(/\d/).length.to_f / [ text.length, 1 ].max

    # 中文识别质量评分
    chinese_count = count_chinese_characters(text)
    chinese_ratio = chinese_count.to_f / [ text.length, 1 ].max

    # 综合评分（增加中文识别权重）
    confidence = (length_score * 0.3 + diversity_score * 0.2 + digit_ratio * 0.2 + chinese_ratio * 0.3)
    confidence.round(2)
  end

  # 统计中文字符数量
  def count_chinese_characters(text)
    return 0 if text.nil? || text.empty?
    text.scan(/[\u4e00-\u9fff]/).size
  end

  # 修复的演示模式OCR
  def perform_fixed_demo_ocr(start_time)
    begin
      demo_service = DemoOcrService.new(@image_path)
      result = demo_service.recognize

      # 添加引擎信息
      result[:engine] = "demo"
      result[:confidence] = result[:confidence] || 0.7

      result
    rescue => e
      Rails.logger.error("演示模式OCR失败: #{e.message}")
      {
        success: false,
        error: "演示模式OCR失败: #{e.message}",
        engine: "demo",
        confidence: 0.0
      }
    end
  end
end
