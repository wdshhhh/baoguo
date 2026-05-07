# 阿里云OCR服务
class AliyunOcrService
  def initialize(image_path)
    @image_path = image_path
    @config = OcrConfig.engine_config('aliyun')
  end

  # 执行OCR识别
  def recognize
    start_time = Time.now

    # 检查配置是否完整
    unless valid_config?
      return {
        success: false,
        error: "阿里云OCR配置不完整，请检查 config/ocr_config.yml"
      }
    end

    # 预处理图片
    process_result = ImageProcessingService.new(@image_path).process
    unless process_result[:success]
      return {
        success: false,
        error: "图片预处理失败: #{process_result[:error]}"
      }
    end

    # 保存临时图片
    temp_path = Rails.root.join('tmp', "aliyun_ocr_#{SecureRandom.uuid}.png")
    process_result[:image].write(temp_path)

    # 调用阿里云OCR API
    result = call_aliyun_ocr(temp_path)

    processing_time = Time.now - start_time

    # 清理临时文件
    File.delete(temp_path) if File.exist?(temp_path)

    if result[:success]
      {
        success: true,
        raw_text: result[:text],
        processing_time: processing_time,
        image_info: process_result[:processed_info],
        engine: 'aliyun'
      }
    else
      {
        success: false,
        error: result[:error]
      }
    end
  rescue => e
    {
      success: false,
      error: "阿里云OCR识别失败: #{e.message}"
    }
  end

  private

  # 检查配置是否有效
  def valid_config?
    @config['access_key_id'].present? &&
      @config['access_key_secret'].present? &&
      @config['access_key_id'] != 'your_access_key_id'
  end

  # 调用阿里云OCR API
  def call_aliyun_ocr(image_path)
    # 注意：这里需要安装阿里云SDK
    # gem 'aliyun_sdk' 或使用HTTP请求直接调用

    # 这里使用HTTP方式直接调用（为了不引入额外依赖）
    # 实际上阿里云推荐使用官方SDK

    {
      success: false,
      error: "请安装阿里云SDK: gem 'aliyun_sdk' 并配置API Key"
    }
  end
end
