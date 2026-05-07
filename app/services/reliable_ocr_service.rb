# 最可靠的OCR识别服务 - 多引擎并行识别，确保成功率
class ReliableOcrService
  def initialize(image_path)
    @image_path = image_path
    
    Rails.logger.info("=== 最可靠OCR服务初始化 ===")
    Rails.logger.info("图片路径: #{@image_path}")
    Rails.logger.info("图片存在: #{File.exist?(@image_path)}")
    Rails.logger.info("策略: 多引擎并行识别，取最佳结果")
  end

  # 执行最可靠的OCR识别
  def recognize
    start_time = Time.now
    
    Rails.logger.info("=== 启动最可靠OCR识别 ===")
    Rails.logger.info("使用多引擎并行识别策略...")
    
    # 并行运行多个OCR引擎
    results = run_parallel_ocr_engines
    
    # 选择最佳结果
    best_result = select_best_result(results)
    
    processing_time = Time.now - start_time
    best_result[:total_processing_time] = processing_time
    
    Rails.logger.info("✅ 最可靠OCR识别完成")
    Rails.logger.info("   总耗时: #{processing_time.round(2)}秒")
    Rails.logger.info("   使用引擎: #{best_result[:engine]}")
    Rails.logger.info("   识别质量: #{best_result[:quality_score] || 'N/A'}")
    
    best_result
  end

  private

  # 并行运行多个OCR引擎
  def run_parallel_ocr_engines
    engines = [
      { name: :tesseract_primary, method: :run_tesseract_primary },
      { name: :tesseract_enhanced, method: :run_tesseract_enhanced },
      { name: :paddle_simple, method: :run_paddle_simple },
      { name: :paddle_fallback, method: :run_paddle_fallback }
    ]
    
    results = {}
    threads = []
    
    engines.each do |engine|
      threads << Thread.new do
        begin
          result = send(engine[:method])
          results[engine[:name]] = result
          Rails.logger.info("   #{engine[:name]} 完成: #{result[:success] ? '成功' : '失败'}")
        rescue => e
          Rails.logger.error("   #{engine[:name]} 异常: #{e.message}")
          results[engine[:name]] = { success: false, error: e.message, engine: engine[:name] }
        end
      end
    end
    
    threads.each(&:join)
    results
  end

  # 选择最佳结果
  def select_best_result(results)
    successful_results = results.values.select { |r| r[:success] }
    
    if successful_results.empty?
      Rails.logger.warn("❌ 所有OCR引擎识别失败")
      return create_fallback_result(results)
    end
    
    # 根据质量评分选择最佳结果
    scored_results = successful_results.map do |result|
      score = calculate_quality_score(result)
      result[:quality_score] = score
      result
    end
    
    best_result = scored_results.max_by { |r| r[:quality_score] }
    
    Rails.logger.info("   成功引擎数量: #{successful_results.size}")
    Rails.logger.info("   最佳引擎: #{best_result[:engine]}")
    Rails.logger.info("   最佳质量评分: #{best_result[:quality_score]}")
    
    best_result
  end

  # 计算识别质量评分
  def calculate_quality_score(result)
    score = 0.0
    text = result[:raw_text].to_s
    
    # 文本长度评分
    length_score = [text.length.to_f / 50, 1.0].min * 0.3
    
    # 数字比例评分（快递面单通常包含数字）
    digit_ratio = text.scan(/\d/).length.to_f / [text.length, 1].max
    digit_score = digit_ratio * 0.3
    
    # 中文字符评分
    chinese_count = text.scan(/[\u4e00-\u9fff]/).size
    chinese_ratio = chinese_count.to_f / [text.length, 1].max
    chinese_score = chinese_ratio * 0.2
    
    # 置信度评分
    confidence_score = (result[:confidence] || 0.5) * 0.2
    
    # 引擎偏好评分
    engine_bonus = case result[:engine]
                   when /tesseract/ then 0.1  # 优先使用Tesseract
                   when /paddle/ then 0.05    # 其次使用PaddleOCR
                   else 0
                   end
    
    score = length_score + digit_score + chinese_score + confidence_score + engine_bonus
    score.round(3)
  end

  # 创建降级结果
  def create_fallback_result(results)
    errors = results.values.map { |r| r[:error] }.compact.uniq
    
    {
      success: false,
      error: "所有OCR引擎识别失败。错误信息: #{errors.join('; ')}",
      engine: "none",
      fallback: true,
      suggestion: "请检查图片质量、清晰度，或尝试手动输入信息"
    }
  end

  # === 各种OCR引擎实现 ===

  # 主要Tesseract引擎
  def run_tesseract_primary
    start_time = Time.now
    
    service = FixedOcrService.new(@image_path)
    result = service.recognize
    
    if result[:success]
      result[:engine] = "tesseract_primary"
      result[:processing_time] = Time.now - start_time
    end
    
    result
  rescue => e
    { success: false, error: "Tesseract主要引擎失败: #{e.message}", engine: "tesseract_primary" }
  end

  # 增强版Tesseract引擎
  def run_tesseract_enhanced
    start_time = Time.now
    
    # 使用优化的预处理参数
    require 'mini_magick'
    
    # 图片预处理
    image = MiniMagick::Image.open(@image_path)
    
    # 增强处理：灰度化、对比度增强、降噪
    image.combine_options do |c|
      c.colorspace 'Gray'
      c.contrast_stretch '2%'
      c.sharpen '0x1'
      c.resize '120%'
    end
    
    temp_path = "/tmp/enhanced_#{File.basename(@image_path)}"
    image.write(temp_path)
    
    # 使用预处理后的图片进行识别
    service = FixedOcrService.new(temp_path)
    result = service.recognize
    
    # 清理临时文件
    File.delete(temp_path) if File.exist?(temp_path)
    
    if result[:success]
      result[:engine] = "tesseract_enhanced"
      result[:processing_time] = Time.now - start_time
      result[:preprocessed] = true
    end
    
    result
  rescue => e
    { success: false, error: "Tesseract增强引擎失败: #{e.message}", engine: "tesseract_enhanced" }
  end

  # 简化版PaddleOCR引擎
  def run_paddle_simple
    start_time = Time.now
    
    # 使用最稳定的PaddleOCR配置
    python_script = <<~PYTHON
import sys
import os
import time
import json

def recognize_image(image_path):
    try:
        # 禁用所有复杂功能
        os.environ['FLAGS_use_mkldnn'] = '0'
        os.environ['FLAGS_use_cinn'] = '0'
        
        # 导入PaddleOCR
        from paddleocr import PaddleOCR
        
        # 最简配置
        ocr = PaddleOCR(
            use_angle_cls=False,
            use_gpu=False,
            lang='ch',
            show_log=False
        )
        
        # 识别
        result = ocr.ocr(image_path)
        
        # 解析结果
        if result and result[0]:
            text_lines = []
            for line in result[0]:
                if line and len(line) >= 2:
                    text = line[1][0] if isinstance(line[1], (list, tuple)) and len(line[1]) > 0 else str(line[1])
                    text_lines.append(text)
            
            full_text = "\\n".join(text_lines)
            
            return {
                "success": True,
                "text": full_text,
                "confidence": 0.8
            }
        else:
            return {
                "success": False,
                "error": "未识别到文本"
            }
            
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

if __name__ == "__main__":
    image_path = sys.argv[1]
    result = recognize_image(image_path)
    print(json.dumps(result))
PYTHON

    script_path = "/tmp/paddle_simple.py"
    File.write(script_path, python_script)
    
    output = `python3 #{script_path} "#{@image_path}" 2>&1`
    File.delete(script_path) if File.exist?(script_path)
    
    result = JSON.parse(output)
    
    if result["success"]
      {
        success: true,
        raw_text: result["text"],
        confidence: result["confidence"],
        engine: "paddle_simple",
        processing_time: Time.now - start_time
      }
    else
      { success: false, error: "PaddleOCR简化版失败: #{result['error']}", engine: "paddle_simple" }
    end
  rescue => e
    { success: false, error: "PaddleOCR简化版异常: #{e.message}", engine: "paddle_simple" }
  end

  # 降级版PaddleOCR引擎
  def run_paddle_fallback
    start_time = Time.now
    
    # 使用OptimizedOcrService中的修复版PaddleOCR
    service = OptimizedOcrService.new(@image_path)
    
    # 直接调用内部方法，避免Tesseract降级
    result = service.send(:recognize_with_fixed_paddle)
    
    if result[:success]
      result[:engine] = "paddle_fallback"
      result[:processing_time] = Time.now - start_time
    end
    
    result
  rescue => e
    { success: false, error: "PaddleOCR降级版失败: #{e.message}", engine: "paddle_fallback" }
  end
end