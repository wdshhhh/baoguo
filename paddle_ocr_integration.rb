#!/usr/bin/env ruby

# PaddleOCR集成方案测试
require_relative 'config/environment'

puts "=== PaddleOCR集成方案测试 ==="
puts ""

# 1. 检查Python环境
puts "1. Python环境检查:"
puts ""

begin
  python_version = `python3 --version 2>&1`.strip
  pip_version = `pip3 --version 2>&1`.strip
  
  puts "   ✅ #{python_version}"
  puts "   ✅ #{pip_version}"
  
  # 检查是否已安装PaddleOCR
  paddleocr_check = `python3 -c "import paddleocr; print('PaddleOCR已安装')" 2>&1`
  
  if $?.success?
    puts "   ✅ PaddleOCR已安装"
  else
    puts "   ❌ PaddleOCR未安装"
    puts "     安装命令: pip3 install paddleocr paddlepaddle"
  end
  
rescue => e
  puts "   ❌ Python环境检查失败: #{e.message}"
end

puts ""

# 2. 创建PaddleOCR服务类
puts "2. 创建PaddleOCR集成服务:"
puts ""

paddle_ocr_service_code = <<~RUBY
class PaddleOcrService
  def initialize(image_path)
    @image_path = image_path
    @use_paddle = check_paddle_available
  end

  def recognize
    if @use_paddle
      perform_paddle_ocr
    else
      # 回退到Tesseract
      fallback_service = FixedOcrService.new(@image_path)
      fallback_service.recognize
    end
  end

  private

  def check_paddle_available
    # 检查PaddleOCR是否可用
    system("python3 -c 'import paddleocr' 2>/dev/null")
  end

  def perform_paddle_ocr
    begin
      # 调用Python脚本进行OCR识别
      result = call_paddle_ocr_script
      
      {
        success: true,
        raw_text: result[:text],
        engine: 'paddleocr',
        confidence: result[:confidence] || 0.8,
        processing_time: result[:time] || 0
      }
      
    rescue => e
      Rails.logger.error("PaddleOCR识别失败: #{e.message}")
      {
        success: false,
        error: "PaddleOCR识别失败: #{e.message}"
      }
    end
  end

  def call_paddle_ocr_script
    # 创建Python脚本
    python_script = <<~PYTHON
import sys
import os
import time
from paddleocr import PaddleOCR

def recognize_image(image_path):
    try:
        # 初始化PaddleOCR
        ocr = PaddleOCR(use_angle_cls=True, lang='ch')
        
        # 开始计时
        start_time = time.time()
        
        # 进行OCR识别
        result = ocr.ocr(image_path, cls=True)
        
        # 计算处理时间
        processing_time = time.time() - start_time
        
        # 提取识别文本
        text_lines = []
        if result and result[0]:
            for line in result[0]:
                if line and len(line) >= 2:
                    text = line[1][0] if isinstance(line[1], (list, tuple)) and len(line[1]) > 0 else str(line[1])
                    confidence = line[1][1] if isinstance(line[1], (list, tuple)) and len(line[1]) > 1 else 0.8
                    text_lines.append({
                        'text': text,
                        'confidence': confidence
                    })
        
        # 合并所有文本
        full_text = "\\n".join([line['text'] for line in text_lines])
        
        # 计算平均置信度
        avg_confidence = sum([line['confidence'] for line in text_lines]) / len(text_lines) if text_lines else 0.8
        
        return {
            'success': True,
            'text': full_text,
            'confidence': avg_confidence,
            'time': processing_time,
            'lines': text_lines
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

if __name__ == "__main__":
    image_path = sys.argv[1] if len(sys.argv) > 1 else None
    if image_path and os.path.exists(image_path):
        result = recognize_image(image_path)
        print(str(result))
    else:
        print({"success": False, "error": "图片路径无效"})
PYTHON

    # 保存Python脚本
    script_path = '/tmp/paddle_ocr_script.py'
    File.write(script_path, python_script)
    
    # 执行Python脚本
    output = `python3 #{script_path} #{@image_path} 2>&1`
    
    # 解析结果
    begin
      result = eval(output.strip)
      result
    rescue => e
      {
        'success': false,
        'error': "结果解析失败: #{e.message}"
      }
    end
  end
end
RUBY

puts "   ✅ PaddleOCR服务类代码已生成"
puts ""

# 3. 测试PaddleOCR集成
puts "3. 测试PaddleOCR集成:"
puts ""

# 创建测试图片
chinese_test_path = "/tmp/paddle_chinese_test_#{Time.now.to_i}.jpg"
system("convert -size 600x400 xc:white -pointsize 28 -fill black -gravity center -annotate +0+0 '顺丰快递\\n运单号: SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{chinese_test_path}")

if File.exist?(chinese_test_path)
  puts "   ✅ 中文测试图片创建成功"
  
  # 测试PaddleOCR识别
  puts "   - 测试PaddleOCR中文识别:"
  
  begin
    # 创建简单的Python测试脚本
    test_script = <<~PYTHON
import sys
import os

try:
    # 检查PaddleOCR是否可用
    from paddleocr import PaddleOCR
    print("PaddleOCR可用")
    
    # 简单的文本识别测试
    ocr = PaddleOCR(use_angle_cls=True, lang='ch')
    result = ocr.ocr('#{chinese_test_path}', cls=True)
    
    if result and result[0]:
        text_lines = []
        for line in result[0]:
            if line and len(line) >= 2:
                text = line[1][0] if isinstance(line[1], (list, tuple)) and len(line[1]) > 0 else str(line[1])
                text_lines.append(text)
        
        full_text = "\\n".join(text_lines)
        print("识别成功:")
        print(full_text)
        
        # 统计中文字符
        chinese_chars = [c for c in full_text if '\\u4e00' <= c <= '\\u9fff']
        print(f"中文字符数: {len(chinese_chars)}")
        
    else:
        print("识别失败: 无结果")
        
except ImportError:
    print("PaddleOCR未安装")
except Exception as e:
    print(f"识别失败: {str(e)}")
PYTHON

    script_path = '/tmp/paddle_test.py'
    File.write(script_path, test_script)
    
    output = `python3 #{script_path} 2>&1`
    puts "     测试结果:"
    puts "     " + "-" * 40
    output.lines.each { |line| puts "     #{line}" }
    puts "     " + "-" * 40
    
  rescue => e
    puts "     ❌ 测试失败: #{e.message}"
  end
  
  # 清理测试文件
  File.delete(chinese_test_path)
  
else
  puts "   ❌ 测试图片创建失败"
end

puts ""

# 4. 替代方案评估
puts "4. 替代OCR方案评估:"
puts ""

puts "   ✅ PaddleOCR优势:"
puts "     - 中文识别准确率高"
puts "     - 支持多种语言"
puts "     - 基于深度学习"
puts "     - 开源免费"
puts ""

puts "   ⚠️ 安装要求:"
puts "     - Python 3.6+"
puts "     - PaddlePaddle深度学习框架"
puts "     - 约1GB磁盘空间"
puts ""

puts "   🔧 集成方案:"
puts "     - 通过Python脚本桥接Ruby"
puts "     - 支持服务降级机制"
puts "     - 可配置优先使用PaddleOCR"

puts ""
puts "=== PaddleOCR集成方案测试完成 ==="