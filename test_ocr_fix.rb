#!/usr/bin/env ruby

# OCR功能修复测试脚本
require_relative 'config/environment'

puts "=== OCR功能修复测试 ==="
puts ""

# 测试1：检查Tesseract是否可用
puts "1. 检查Tesseract状态..."
begin
  result = `which tesseract 2>&1`
  if $?.success?
    version = `tesseract --version 2>&1`
    puts "   ✓ Tesseract已安装: #{version.split('\n').first}"
    
    # 检查语言包
    langs = `tesseract --list-langs 2>&1`
    if langs.include?('chi_sim')
      puts "   ✓ 中文语言包已安装"
    else
      puts "   ⚠ 中文语言包未安装，将使用演示模式"
    end
  else
    puts "   ⚠ Tesseract未安装，将使用演示模式"
  end
rescue => e
  puts "   ❌ Tesseract检查失败: #{e.message}"
end

puts ""

# 测试2：检查OCR服务是否正常
puts "2. 检查OCR服务..."
begin
  # 创建一个简单的测试图片
  test_image_path = "/tmp/test_ocr_image.jpg"
  system("convert -size 300x200 xc:white -pointsize 20 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890' #{test_image_path}")
  
  if File.exist?(test_image_path)
    puts "   ✓ 测试图片创建成功"
    
    # 测试FixedOcrService
    service = FixedOcrService.new(test_image_path)
    result = service.recognize
    
    if result[:success]
      puts "   ✓ FixedOcrService识别成功"
      puts "     引擎: #{result[:engine]}"
      puts "     置信度: #{result[:confidence]}"
      puts "     识别文本: #{result[:raw_text][0..50]}..."
    else
      puts "   ❌ FixedOcrService识别失败: #{result[:error]}"
    end
    
    # 测试DemoOcrService
    demo_service = DemoOcrService.new(test_image_path)
    demo_result = demo_service.recognize
    
    if demo_result[:success]
      puts "   ✓ DemoOcrService识别成功"
      puts "     识别文本: #{demo_result[:raw_text][0..50]}..."
    else
      puts "   ❌ DemoOcrService识别失败: #{demo_result[:error]}"
    end
    
    # 测试AiEnhancedOcrService
    require 'action_controller'
    
    class MockImage
      attr_reader :original_filename
      
      def initialize(path)
        @path = path
        @original_filename = File.basename(path)
      end
      
      def read
        File.binread(@path)
      end
      
      def size
        File.size(@path)
      end
    end
    
    ai_service = AiEnhancedOcrService.new
    mock_image = MockImage.new(test_image_path)
    ai_result = ai_service.recognize_parcel_with_ai(mock_image)
    
    if ai_result[:success]
      puts "   ✓ AiEnhancedOcrService识别成功"
      data = ai_result[:data]
      puts "     运单号: #{data[:tracking_number]}"
      puts "     收件人: #{data[:customer_name]}"
      puts "     手机号: #{data[:customer_phone]}"
      puts "     置信度: #{data[:confidence]}"
    else
      puts "   ❌ AiEnhancedOcrService识别失败: #{ai_result[:error]}"
    end
    
    # 清理测试图片
    File.delete(test_image_path)
  else
    puts "   ❌ 测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ OCR服务测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\n      ')}"
end

puts ""

# 测试3：检查OCR解析器
puts "3. 检查OCR解析器..."
begin
  test_text = "顺丰快递 SF1234567890\n收件人: 张三\n手机: 13800138000\n地址: 北京市朝阳区"
  parser = OcrResultParser.new(test_text)
  parsed_data = parser.parse
  
  puts "   ✓ OCR解析器工作正常"
  puts "     运单号: #{parsed_data[:tracking_number]}"
  puts "     收件人: #{parsed_data[:recipient_name]}"
  puts "     手机号: #{parsed_data[:recipient_phone]}"
  puts "     快递公司: #{parsed_data[:courier_company]}"
  
rescue => e
  puts "   ❌ OCR解析器测试失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "使用说明:"
puts "1. 访问 http://localhost:3000/pc/packages"
puts "2. 点击'新增包裹'按钮"
puts "3. 使用'OCR识别面单'功能上传测试图片"
puts "4. 验证自动填充效果"
puts ""
puts "测试图片位置: /tmp/ocr_test_images/"
puts "可用的测试图片:"
Dir.glob("/tmp/ocr_test_images/*.jpg").each do |file|
  puts "   - #{File.basename(file)}"
end