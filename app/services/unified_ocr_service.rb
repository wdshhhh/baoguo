# 统一OCR服务接口
class UnifiedOcrService
  def initialize(image_path, engine = nil)
    @image_path = image_path
    @engine = engine || OcrConfig.current_engine
  end

  # 执行OCR识别
  def recognize
    start_time = Time.now
    Rails.logger.info "使用 #{@engine} 引擎开始OCR识别"

    case @engine
    when 'tesseract'
      result = TesseractOcrService.new(@image_path).recognize
    when 'aliyun'
      result = AliyunOcrService.new(@image_path).recognize
    when 'baidu'
      result = BaiduOcrService.new(@image_path).recognize
    when 'demo'
      result = DemoOcrService.new(@image_path).recognize
    else
      result = { success: false, error: "未知的OCR引擎: #{@engine}" }
    end

    processing_time = Time.now - start_time

    if result[:success]
      Rails.logger.info "#{@engine} 引擎识别成功，耗时 #{sprintf('%.2f', processing_time)}秒"
    else
      Rails.logger.error "#{@engine} 引擎识别失败: #{result[:error]}"
      # 自动降级到演示模式
      if @engine != 'demo'
        Rails.logger.info "自动降级到 demo 引擎"
        return DemoOcrService.new(@image_path).recognize
      end
    end

    result
  end

  # 获取可用引擎列表
  def self.available_engines
    OcrConfig.available_engines
  end

  # 切换引擎
  def self.switch_engine!(engine)
    if OcrConfig.available_engines.include?(engine)
      OcrConfig.set_engine!(engine)
      { success: true, engine: engine }
    else
      { success: false, error: "引擎 #{engine} 不可用" }
    end
  end
end
