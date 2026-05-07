#!/usr/bin/env ruby

# 详细调试PaddleOCR服务
require_relative 'config/environment'

puts "=== 详细调试PaddleOCR服务 ==="
puts ""

# 1. 检查Python环境
puts "1. 检查Python环境:"
puts "   Python3版本: #{`python3 --version 2>&1`.strip}"
puts "   Python路径: #{`which python3`.strip}"
puts ""

# 2. 检查PaddleOCR安装
puts "2. 检查PaddleOCR安装:"
check_script = <<~PYTHON
import sys
print("Python路径:", sys.path)
try:
    import paddleocr
    print("✅ PaddleOCR导入成功")
    print("   版本:", paddleocr.__version__)
    print("   路径:", paddleocr.__file__)
    
    # 检查模型文件
    import os
    paddleocr_dir = os.path.dirname(paddleocr.__file__)
    print("   PaddleOCR目录:", paddleocr_dir)
    
    # 检查模型文件是否存在
    model_files = []
    for root, dirs, files in os.walk(paddleocr_dir):
        for file in files:
            if file.endswith('.pdiparams') or file.endswith('.pdmodel'):
                model_files.append(os.path.join(root, file))
    
    print("   找到模型文件数量:", len(model_files))
    if model_files:
        print("   模型文件示例:", model_files[0])
    
    # 尝试初始化OCR
    print("\\n   尝试初始化PaddleOCR...")
    ocr = paddleocr.PaddleOCR(use_angle_cls=True, lang='ch')
    print("   ✅ PaddleOCR初始化成功")
    
except ImportError as e:
    print("❌ PaddleOCR导入失败:", e)
except Exception as e:
    print("❌ PaddleOCR初始化失败:", e)
    import traceback
    print("错误堆栈:")
    traceback.print_exc()
PYTHON

File.write('/tmp/debug_paddleocr.py', check_script)
puts `python3 /tmp/debug_paddleocr.py 2>&1`
File.delete('/tmp/debug_paddleocr.py') if File.exist?('/tmp/debug_paddleocr.py')
puts ""

# 3. 创建测试图片
puts "3. 创建测试图片..."
require 'mini_magick'

# 创建一个简单的测试图片（使用系统字体）
image = MiniMagick::Tool::Convert.new do |convert|
  convert.size '600x400'
  convert.xc 'white'
  convert.font 'DejaVu-Sans'
  convert.pointsize 20
  convert.fill 'black'
  convert.gravity 'center'
  convert.annotate '0,0', '顺丰快递 SF1234567890'
  convert << '/tmp/simple_test.jpg'
end

puts "   测试图片创建成功: /tmp/simple_test.jpg"
puts ""

# 4. 直接测试PaddleOCR Python脚本
puts "4. 直接测试PaddleOCR Python脚本:"

paddle_script = <<~PYTHON
import sys
import os
import json
import time

def test_paddleocr(image_path):
    try:
        print("   开始导入PaddleOCR...")
        from paddleocr import PaddleOCR
        
        print("   初始化PaddleOCR...")
        ocr = PaddleOCR(use_angle_cls=True, lang='ch')
        
        print("   开始OCR识别...")
        start_time = time.time()
        result = ocr.ocr(image_path)
        processing_time = time.time() - start_time
        
        print("   OCR识别完成，处理时间: {:.2f}秒".format(processing_time))
        
        if result and result[0]:
            print("   识别到 {} 行文本".format(len(result[0])))
            
            text_lines = []
            for i, line in enumerate(result[0]):
                if line and len(line) >= 2:
                    text_info = line[1]
                    if isinstance(text_info, (list, tuple)) and len(text_info) > 0:
                        text = text_info[0]
                        confidence = text_info[1] if len(text_info) > 1 else 0.8
                        text_lines.append({
                            'text': text,
                            'confidence': confidence
                        })
                        print("   第{}行: {} (置信度: {})".format(i+1, text, confidence))
            
            full_text = "\\n".join([line['text'] for line in text_lines])
            
            return {
                'success': True,
                'text': full_text,
                'confidence': sum([line['confidence'] for line in text_lines]) / len(text_lines) if text_lines else 0.8,
                'time': processing_time,
                'lines_count': len(text_lines)
            }
        else:
            print("   未识别到任何文本")
            return {
                'success': False,
                'error': '未识别到任何文本'
            }
            
    except Exception as e:
        print("   ❌ OCR识别失败:", str(e))
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'error': str(e)
        }

if __name__ == "__main__":
    image_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/simple_test.jpg'
    print("   图片路径:", image_path)
    print("   图片存在:", os.path.exists(image_path))
    
    result = test_paddleocr(image_path)
    print("\\n   最终结果:")
    print(json.dumps(result, ensure_ascii=False, indent=2))
PYTHON

File.write('/tmp/test_paddleocr_direct.py', paddle_script)
puts `python3 /tmp/test_paddleocr_direct.py 2>&1`
File.delete('/tmp/test_paddleocr_direct.py') if File.exist?('/tmp/test_paddleocr_direct.py')
puts ""

# 5. 测试PaddleOCR服务类
puts "5. 测试PaddleOCR服务类:"
begin
  service = PaddleOcrService.new('/tmp/simple_test.jpg')
  puts "   ✅ PaddleOCR服务实例化成功"
  
  result = service.recognize
  puts "   识别结果:"
  puts "   成功: #{result[:success]}"
  puts "   错误: #{result[:error]}" if result[:error]
  puts "   引擎: #{result[:engine]}"
  
  if result[:success]
    puts "   识别文本: #{result[:raw_text].inspect}"
    puts "   置信度: #{result[:confidence]}"
    puts "   处理时间: #{result[:processing_time]}秒"
  end
  
rescue => e
  puts "   ❌ PaddleOCR服务测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\\n   ')}"
end

puts ""
puts "=== 调试完成 ==="