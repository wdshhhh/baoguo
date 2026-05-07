# 优化的OCR服务管理器 - 优先使用Tesseract，确保系统稳定性
class OptimizedOcrService
  def initialize(image_path)
    @image_path = image_path
    @tesseract_service = FixedOcrService.new(image_path)

    Rails.logger.info("=== 优化OCR服务初始化 ===")
    Rails.logger.info("图片路径: #{@image_path}")
    Rails.logger.info("图片存在: #{File.exist?(@image_path)}")
    Rails.logger.info("优先引擎: Tesseract")
  end

  # 执行OCR识别（优先使用Tesseract）
  def recognize
    start_time = Time.now

    Rails.logger.info("=== 优化OCR服务启动 ===")
    Rails.logger.info("优先使用Tesseract进行识别...")

    # 首先尝试Tesseract（最稳定）
    tesseract_result = @tesseract_service.recognize

    if tesseract_result[:success]
      processing_time = Time.now - start_time
      tesseract_result[:processing_time] = processing_time
      tesseract_result[:priority] = "primary"
      tesseract_result[:engine] = "tesseract_optimized"

      Rails.logger.info("✅ Tesseract识别成功")
      Rails.logger.info("   识别耗时: #{processing_time.round(2)}秒")
      Rails.logger.info("   识别文本: #{tesseract_result[:raw_text][0..100]}...")

      return tesseract_result
    end

    Rails.logger.warn("Tesseract识别失败，错误: #{tesseract_result[:error]}")
    Rails.logger.warn("尝试使用修复版PaddleOCR...")

    # Tesseract失败时尝试修复版PaddleOCR
    begin
      paddle_result = recognize_with_fixed_paddle

      if paddle_result[:success]
        processing_time = Time.now - start_time
        paddle_result[:processing_time] = processing_time
        paddle_result[:priority] = "fallback"
        paddle_result[:engine] = "paddleocr_fixed"

        Rails.logger.info("✅ PaddleOCR识别成功（降级模式）")
        Rails.logger.info("   识别耗时: #{processing_time.round(2)}秒")

        return paddle_result
      else
        Rails.logger.warn("PaddleOCR识别失败: #{paddle_result[:error]}")
      end

    rescue => e
      Rails.logger.error("PaddleOCR调用异常: #{e.message}")
    end

    # 两个引擎都失败
    Rails.logger.error("❌ 所有OCR引擎识别失败")
    {
      success: false,
      error: "所有OCR引擎识别失败，请检查图片质量或手动输入",
      tesseract_error: tesseract_result[:error],
      processing_time: Time.now - start_time,
      engine: "none"
    }
  end

  private

  # 使用修复的PaddleOCR进行识别
  def recognize_with_fixed_paddle
    begin
      # 创建修复的Python OCR识别脚本（禁用OneDNN）
      python_script = <<~PYTHON
import sys
import os
import time
import json

def recognize_image(image_path):
    try:
        # 设置环境变量，禁用OneDNN和相关复杂功能
        os.environ['ONEDNN_DEFAULT_FPMATH_MODE'] = 'BF16'
        os.environ['FLAGS_use_mkldnn'] = '0'
        os.environ['FLAGS_use_cinn'] = '0'
        os.environ['FLAGS_eager_delete_tensor_gb'] = '0'
#{'        '}
        # 导入PaddleOCR
        from paddleocr import PaddleOCR
#{'        '}
        # 初始化PaddleOCR（禁用复杂功能，使用最稳定配置）
        ocr = PaddleOCR(
            use_angle_cls=False,    # 禁用角度分类
            use_gpu=False,          # 禁用GPU
            lang='ch',              # 中文模型
            det_limit_side_len=960, # 限制图片尺寸
            det_db_thresh=0.3,      # 降低检测阈值
            det_db_box_thresh=0.5,
            det_db_unclip_ratio=1.6,
            max_text_length=50,     # 限制文本长度
            rec_batch_num=1,        # 单批次处理
            show_log=False          # 禁用详细日志
        )
#{'        '}
        # 开始计时
        start_time = time.time()
#{'        '}
        # 进行OCR识别（禁用cls参数）
        result = ocr.ocr(image_path)
#{'        '}
        # 计算处理时间
        processing_time = time.time() - start_time
#{'        '}
        # 解析结果
        if result and result[0]:
            text_lines = []
            for line in result[0]:
                if line and len(line) >= 2:
                    text = line[1][0] if isinstance(line[1], (list, tuple)) and len(line[1]) > 0 else str(line[1])
                    confidence = line[1][1] if isinstance(line[1], (list, tuple)) and len(line[1]) > 1 else 0.8
                    text_lines.append(text)
#{'            '}
            full_text = "\\n".join(text_lines)
#{'            '}
            # 计算中文字符数量
            chinese_count = sum(1 for char in full_text if '\\u4e00' <= char <= '\\u9fff')
#{'            '}
            return {
                "success": True,
                "text": full_text,
                "confidence": 0.8,  # 固定置信度，避免计算错误
                "chinese_count": chinese_count,
                "lines_count": len(text_lines),
                "processing_time": processing_time
            }
        else:
            return {
                "success": False,
                "error": "未识别到文本"
            }
#{'            '}
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

      script_path = "/tmp/paddle_ocr_optimized.py"
      File.write(script_path, python_script)

      # 执行Python脚本
      output = `python3 #{script_path} "#{@image_path}" 2>&1`

      # 清理临时文件
      File.delete(script_path) if File.exist?(script_path)

      # 解析JSON结果
      result = JSON.parse(output)

      if result["success"]
        {
          success: true,
          raw_text: result["text"],
          confidence: result["confidence"],
          processing_time: result["processing_time"],
          chinese_count: result["chinese_count"],
          lines_count: result["lines_count"]
        }
      else
        {
          success: false,
          error: "PaddleOCR识别失败: #{result['error']}"
        }
      end

    rescue => e
      {
        success: false,
        error: "PaddleOCR调用失败: #{e.message}"
      }
    end
  end
end
