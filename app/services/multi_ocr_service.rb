# 多OCR服务管理器 - 支持服务降级和智能选择
class MultiOcrService
  def initialize(image_path)
    @image_path = image_path

    # 定义OCR服务优先级（按性能从高到低）
    @services = [
      {
          name: :paddle_ocr,
          class: PaddleOcrService,
          priority: 1,
          description: "PaddleOCR - 高性能中文识别"
        },
      {
        name: :tesseract,
        class: FixedOcrService,
        priority: 2,
        description: "Tesseract - 传统OCR引擎"
      }
    ]

    Rails.logger.info("=== 多OCR服务管理器初始化 ===")
    Rails.logger.info("可用服务: #{@services.map { |s| s[:name] }.join(', ')}")
    Rails.logger.info("图片路径: #{@image_path}")
  end

  # 执行OCR识别（智能选择最佳服务）
  def recognize
    start_time = Time.now

    # 按优先级尝试各个服务
    @services.sort_by { |s| s[:priority] }.each do |service|
      begin
        Rails.logger.info("尝试使用 #{service[:name]} 服务...")

        # 创建服务实例
        ocr_service = service[:class].new(@image_path)
        result = ocr_service.recognize

        if result[:success]
          processing_time = Time.now - start_time

          # 添加服务信息
          result[:service_name] = service[:name]
          result[:service_description] = service[:description]
          result[:total_processing_time] = processing_time
          result[:attempts] = @services.index(service) + 1

          Rails.logger.info("✅ #{service[:name]} 识别成功 (耗时: #{processing_time.round(2)}秒)")

          # 如果是PaddleOCR且识别到中文，直接返回
          if service[:name] == :paddle_ocr && result[:chinese_count].to_i > 0
            Rails.logger.info("🎯 PaddleOCR成功识别到 #{result[:chinese_count]} 个中文字符")
            return result
          end

          # 如果是Tesseract，检查是否需要继续尝试其他服务
          if service[:name] == :tesseract
            # 检查识别质量
            if acceptable_quality?(result)
              Rails.logger.info("✅ Tesseract识别质量可接受")
              return result
            else
              Rails.logger.warn("⚠️ Tesseract识别质量不佳，但无其他可用服务")
              return result
            end
          end

          return result
        else
          Rails.logger.warn("❌ #{service[:name]} 识别失败: #{result[:error]}")
        end

      rescue => e
        Rails.logger.error("❌ #{service[:name]} 服务异常: #{e.message}")
      end
    end

    # 所有服务都失败
    processing_time = Time.now - start_time
    {
      success: false,
      error: "所有OCR服务均失败",
      service_name: :all_failed,
      total_processing_time: processing_time,
      attempts: @services.size
    }
  end

  # 强制使用特定服务
  def recognize_with_service(service_name)
    service = @services.find { |s| s[:name] == service_name }

    unless service
      return {
        success: false,
        error: "服务 #{service_name} 不存在"
      }
    end

    Rails.logger.info("强制使用 #{service_name} 服务...")

    begin
      ocr_service = service[:class].new(@image_path)
      result = ocr_service.recognize

      if result[:success]
        result[:service_name] = service_name
        result[:service_description] = service[:description]
        result[:forced] = true
      end

      result
    rescue => e
      {
        success: false,
        error: "强制使用 #{service_name} 失败: #{e.message}"
      }
    end
  end

  # 获取所有可用服务状态
  def service_status
    status = {}

    @services.each do |service|
      begin
        # 创建临时实例检查服务状态
        temp_service = service[:class].new(@image_path)

        if service[:class] == PaddleOcrService
          # PaddleOCR特殊检查
          available = temp_service.send(:check_paddle_available)
        else
          # 其他服务默认可用
          available = true
        end

        status[service[:name]] = {
          available: available,
          description: service[:description],
          priority: service[:priority]
        }

      rescue => e
        status[service[:name]] = {
          available: false,
          description: service[:description],
          priority: service[:priority],
          error: e.message
        }
      end
    end

    status
  end

  # 性能测试（对比所有服务）
  def benchmark_services
    benchmark_results = {}

    @services.each do |service|
      begin
        Rails.logger.info("性能测试: #{service[:name]}...")

        start_time = Time.now
        ocr_service = service[:class].new(@image_path)
        result = ocr_service.recognize
        processing_time = Time.now - start_time

        benchmark_results[service[:name]] = {
          success: result[:success],
          processing_time: processing_time,
          confidence: result[:confidence] || 0,
          chinese_count: result[:chinese_count] || 0,
          error: result[:error]
        }

        Rails.logger.info("#{service[:name]} 测试完成: #{result[:success] ? '成功' : '失败'}")

      rescue => e
        benchmark_results[service[:name]] = {
          success: false,
          error: e.message
        }
        Rails.logger.error("#{service[:name]} 测试异常: #{e.message}")
      end
    end

    benchmark_results
  end

  private

  # 检查识别质量是否可接受
  def acceptable_quality?(result)
    return false unless result[:success]

    # 检查置信度
    return false if result[:confidence].to_f < 0.3

    # 检查是否有有效文本
    return false if result[:raw_text].to_s.strip.empty?

    # 检查是否包含关键信息（运单号、手机号等）
    text = result[:raw_text].to_s

    # 运单号模式（字母+数字，8-15位）
    tracking_pattern = /[A-Za-z]{2,4}\d{6,12}/

    # 手机号模式（11位数字）
    phone_pattern = /1[3-9]\d{9}/

    has_tracking = text.match?(tracking_pattern)
    has_phone = text.match?(phone_pattern)

    # 至少包含运单号或手机号
    has_tracking || has_phone
  end

  # 智能选择最佳服务（基于历史性能）
  def select_best_service
    # 简单策略：优先使用PaddleOCR，如果不可用则使用Tesseract
    paddle_service = @services.find { |s| s[:name] == :paddle_ocr }

    if paddle_service
      # 检查PaddleOCR是否可用
      temp_service = paddle_service[:class].new(@image_path)
      if temp_service.respond_to?(:check_paddle_available)
        available = temp_service.send(:check_paddle_available)
        return :paddle_ocr if available
      end
    end

    # 默认使用Tesseract
    :tesseract
  end
end
