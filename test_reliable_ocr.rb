#!/usr/bin/env ruby

# 测试最可靠的OCR识别方案
require_relative 'config/environment'

puts "=== 测试最可靠OCR识别方案 ==="
puts ""

# 创建测试图片
puts "1. 创建测试图片..."
begin
  require 'mini_magick'
  
  # 创建包含快递面单信息的测试图片
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 18
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+20+20', '韵达快递'
    convert.annotate '+20+60', '运单号: YD123456789'
    convert.annotate '+20+100', '收件人: 张三'
    convert.annotate '+20+140', '手机号: 13800138000'
    convert.annotate '+20+180', '地址: 北京市朝阳区'
    convert << '/tmp/test_reliable_ocr.jpg'
  end
  
  puts "   ✅ 测试图片创建成功: /tmp/test_reliable_ocr.jpg"
  
rescue => e
  puts "   ❌ 测试图片创建失败: #{e.message}"
  exit(1)
end

puts ""

# 测试最可靠OCR服务
puts "2. 测试最可靠OCR服务..."
begin
  reliable_service = ReliableOcrService.new('/tmp/test_reliable_ocr.jpg')
  result = reliable_service.recognize
  
  puts "   识别结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
  puts "   使用引擎: #{result[:engine]}"
  puts "   总耗时: #{result[:total_processing_time].round(2)}秒"
  
  if result[:success]
    puts "   识别文本: #{result[:raw_text][0..200]}..."
    puts "   质量评分: #{result[:quality_score] || 'N/A'}"
    
    # 测试OCR结果解析
    puts ""
    puts "3. 测试OCR结果解析..."
    parser = OcrResultParser.new(result[:raw_text])
    parsed_data = parser.parse
    
    puts "   解析结果:"
    puts "     运单号: #{parsed_data[:tracking_number] || '未识别'}"
    puts "     收件人: #{parsed_data[:recipient_name] || '未识别'}"
    puts "     手机号: #{parsed_data[:recipient_phone] || '未识别'}"
    puts "     快递公司: #{parsed_data[:courier_company] || '未识别'}"
    puts "     地址: #{parsed_data[:recipient_address] || '未识别'}"
    
  else
    puts "   错误信息: #{result[:error]}"
    if result[:suggestion]
      puts "   建议: #{result[:suggestion]}"
    end
  end
  
rescue => e
  puts "   ❌ 最可靠OCR服务测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 测试AI增强OCR服务
puts "4. 测试AI增强OCR服务..."
begin
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_reliable_ocr.jpg')
  
  puts "   AI增强识别结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
  
  if result[:success]
    puts "   返回数据:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
  else
    puts "   错误信息: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ AI增强OCR服务测试失败: #{e.message}"
end

puts ""

# 测试不同质量的图片
puts "5. 测试不同质量图片识别..."
begin
  # 创建模糊图片
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 18
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+20+20', '顺丰快递 SF987654321'
    convert.annotate '+20+60', '收件人: 李四'
    convert.annotate '+20+100', '手机号: 13900139000'
    convert << '/tmp/test_blur.jpg'
  end
  
  # 添加模糊效果
  image = MiniMagick::Image.open('/tmp/test_blur.jpg')
  image.blur('0x2')  # 轻微模糊
  image.write('/tmp/test_blur.jpg')
  
  puts "   ✅ 模糊测试图片创建成功"
  
  # 测试模糊图片识别
  reliable_service = ReliableOcrService.new('/tmp/test_blur.jpg')
  result = reliable_service.recognize
  
  puts "   模糊图片识别结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
  puts "   使用引擎: #{result[:engine]}"
  
  if result[:success]
    puts "   识别文本: #{result[:raw_text][0..100]}..."
    puts "   质量评分: #{result[:quality_score]}"
  end
  
rescue => e
  puts "   ❌ 模糊图片测试失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "总结:"
puts "- 最可靠OCR服务使用多引擎并行识别策略"
puts "- 支持Tesseract和PaddleOCR多种引擎"
puts "- 自动选择质量评分最高的识别结果"
puts "- 包含完善的错误处理和降级机制"
puts "- 能够处理不同质量的图片"
puts ""
puts "现在系统将使用最可靠的OCR识别方案，确保面单识别成功率最大化！"