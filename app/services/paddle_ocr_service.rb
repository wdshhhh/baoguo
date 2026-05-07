# PaddleOCR服务类 - 提供高性能中文OCR识别
class PaddleOcrService
  def initialize(image_path)
    @image_path = image_path
    @use_paddle = check_paddle_available

    Rails.logger.info("=== PaddleOCR系统初始化 ===")
    Rails.logger.info("当前引擎: #{@use_paddle ? 'paddleocr' : '不可用'}")
    Rails.logger.info("图片路径: #{@image_path}")
    Rails.logger.info("图片存在: #{File.exist?(@image_path)}")
  end

  # 执行OCR识别
  def recognize
    start_time = Time.now

    if @use_paddle
      Rails.logger.info("使用PaddleOCR进行中文OCR识别...")
      result = perform_paddle_ocr(start_time)
      Rails.logger.info("PaddleOCR识别完成: #{result[:success] ? '成功' : '失败'}")
      result
    else
      Rails.logger.warn("PaddleOCR不可用，回退到Tesseract...")
      # 回退到FixedOcrService
      fallback_service = FixedOcrService.new(@image_path)
      fallback_result = fallback_service.recognize

      # 标记为降级识别
      if fallback_result[:success]
        fallback_result[:engine] = "tesseract_fallback"
        fallback_result[:fallback] = true
      end

      fallback_result
    end
  rescue => e
    Rails.logger.error("PaddleOCR识别失败: #{e.message}")
    Rails.logger.error("错误堆栈: #{e.backtrace.join('\n')}")

    # 发生错误时自动回退到Tesseract
    Rails.logger.warn("发生错误，回退到Tesseract...")
    fallback_service = FixedOcrService.new(@image_path)
    fallback_service.recognize
  end

  # 获取OCR引擎信息
  def engine_info
    {
      name: "PaddleOCR",
      version: "3.5.0",
      language: "中文",
      description: "基于深度学习的OCR引擎，中文识别能力强",
      available: @use_paddle
    }
  end

  private

  # 检查PaddleOCR是否可用
  def check_paddle_available
    begin
      # 检查Python环境和PaddleOCR
      check_script = <<~PYTHON
import sys
try:
    import paddleocr
    print("available")
except ImportError:
    print("unavailable")
PYTHON

      script_path = "/tmp/check_paddle.py"
      File.write(script_path, check_script)

      output = `python3 #{script_path} 2>&1`.strip
      File.delete(script_path) if File.exist?(script_path)

      output == "available"
    rescue => e
      Rails.logger.warn("PaddleOCR检查失败: #{e.message}")
      false
    end
  end

  # 执行PaddleOCR识别
  def perform_paddle_ocr(start_time)
    begin
      # 调用Python脚本进行OCR识别
      result = call_paddle_ocr_script

      processing_time = Time.now - start_time

      if result["success"]
        {
          success: true,
          raw_text: result["text"],
          engine: "paddleocr",
          confidence: result["confidence"] || calculate_paddle_confidence(result["text"]),
          processing_time: processing_time,
          chinese_count: result["chinese_count"] || 0,
          lines_count: result["lines_count"] || 0
        }
      else
        {
          success: false,
          error: "PaddleOCR识别失败: #{result['error']}",
          engine: "paddleocr",
          processing_time: processing_time
        }
      end

    rescue => e
      Rails.logger.error("PaddleOCR调用失败: #{e.message}")
      {
        success: false,
        error: "PaddleOCR调用失败: #{e.message}"
      }
    end
  end

  # 调用PaddleOCR Python脚本
  def call_paddle_ocr_script
    # 创建简化的Python OCR识别脚本
    python_script = <<~PYTHON
import sys
import os
import time
import json

def recognize_image(image_path):
    try:
        # 导入PaddleOCR
        from paddleocr import PaddleOCR
#{'        '}
        # 初始化PaddleOCR（中文模型）
        ocr = PaddleOCR(
            use_angle_cls=True,  # 使用角度分类
            lang='ch'            # 中文模型
        )
#{'        '}
        # 开始计时
        start_time = time.time()
#{'        '}
        # 进行OCR识别
        result = ocr.ocr(image_path)
#{'        '}
        # 计算处理时间
        processing_time = time.time() - start_time
#{'        '}
        # 提取识别文本
        text_lines = []
        if result and result[0]:
            for line in result[0]:
                if line and len(line) >= 2:
                    text_info = line[1]
                    if isinstance(text_info, (list, tuple)) and len(text_info) > 0:
                        text = text_info[0]
                        confidence = text_info[1] if len(text_info) > 1 else 0.8
                        text_lines.append({
                            'text': text,
                            'confidence': confidence
                        })
#{'        '}
        # 合并所有文本
        full_text = "\\n".join([line['text'] for line in text_lines])
#{'        '}
        # 统计中文字符
        chinese_chars = [c for c in full_text if '\\u4e00' <= c <= '\\u9fff']
#{'        '}
        # 计算平均置信度
        avg_confidence = sum([line['confidence'] for line in text_lines]) / len(text_lines) if text_lines else 0.8
#{'        '}
        return {
            'success': True,
            'text': full_text,
            'confidence': avg_confidence,
            'time': processing_time,
            'chinese_count': len(chinese_chars),
            'lines_count': len(text_lines),
            'lines': text_lines
        }
#{'        '}
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

if __name__ == "__main__":
    image_path = sys.argv[1] if len(sys.argv) > 1 else None
    if image_path and os.path.exists(image_path):
        result = recognize_image(image_path)
        # 输出JSON格式结果
        print(json.dumps(result, ensure_ascii=False))
    else:
        print(json.dumps({"success": False, "error": "图片路径无效"}, ensure_ascii=False))
PYTHON

    # 保存Python脚本
    script_path = "/tmp/paddle_ocr_script.py"
    File.write(script_path, python_script)

    # 执行Python脚本
    command = "python3 #{script_path} '#{@image_path}' 2>&1"
    output = `#{command}`

    # 清理脚本文件
    File.delete(script_path) if File.exist?(script_path)

    # 解析JSON结果
    begin
      # 清理输出，只保留JSON内容
      json_output = output.strip

      # 如果输出包含Python错误信息，提取JSON部分
      if json_output.include?("{")
        json_start = json_output.index("{")
        json_end = json_output.rindex("}") + 1
        json_output = json_output[json_start...json_end]
      end

      JSON.parse(json_output)
    rescue => e
      Rails.logger.error("PaddleOCR结果解析失败: #{e.message}")
      Rails.logger.error("原始输出: #{output}")
      {
        "success" => false,
        "error" => "结果解析失败: #{e.message}"
      }
    end
  end

  # 计算PaddleOCR识别置信度
  def calculate_paddle_confidence(text)
    # 基于文本质量和长度计算置信度
    confidence = 0.5  # 基础置信度

    # 文本长度加分
    confidence += [ text.length.to_f / 100, 0.3 ].min

    # 中文字符比例加分
    chinese_chars = text.scan(/[\u4e00-\u9fa5]/)
    chinese_ratio = chinese_chars.size.to_f / [ text.length, 1 ].max
    confidence += chinese_ratio * 0.2

    # 置信度限制在0.1-0.95之间
    [ 0.1, confidence, 0.95 ].sort[1]
  end
end
