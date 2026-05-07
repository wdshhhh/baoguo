#!/usr/bin/env ruby

# 增强版AI面单识别测试
require_relative 'config/environment'

puts "=== 增强版AI面单识别测试 ==="
puts ""

# 1. 创建更清晰的测试图片
puts "1. 创建更清晰的测试图片..."
begin
  require 'mini_magick'
  
  # 创建更清晰的快递面单测试图片
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '1000x800'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 24
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+50+50', '顺丰快递 SF1234567890'
    convert.annotate '+50+100', '收件人: 张三'
    convert.annotate '+50+150', '手机号: 13800138000'
    convert.annotate '+50+200', '地址: 北京市朝阳区建国门外大街1号'
    convert.annotate '+50+250', '重量: 1.5kg'
    convert.annotate '+50+300', '备注: 请妥善保管'
    convert.annotate '+50+350', '寄件人: 李四 13900139000'
    convert.annotate '+50+400', '寄件地址: 上海市浦东新区陆家嘴'
    convert << '/tmp/test_ai_enhanced.jpg'
  end
  
  puts "   ✅ 增强测试图片创建成功: /tmp/test_ai_enhanced.jpg"
  
rescue => e
  puts "   ❌ 测试图片创建失败: #{e.message}"
  exit(1)
end

puts ""

# 2. 测试OCR文本提取
puts "2. 测试OCR文本提取..."
begin
  reliable_service = ReliableOcrService.new('/tmp/test_ai_enhanced.jpg')
  ocr_result = reliable_service.recognize
  
  puts "   OCR识别结果: #{ocr_result[:success] ? '✅ 成功' : '❌ 失败'}"
  puts "   使用引擎: #{ocr_result[:engine]}"
  puts "   处理时间: #{ocr_result[:processing_time].round(2)}秒"
  
  if ocr_result[:success]
    puts "   识别文本: #{ocr_result[:raw_text]}"
    puts "   文本长度: #{ocr_result[:raw_text].length} 字符"
    
    # 检查文本中是否包含关键信息
    text = ocr_result[:raw_text]
    puts "   包含顺丰: #{text.include?('顺丰')}"
    puts "   包含SF: #{text.include?('SF')}"
    puts "   包含张三: #{text.include?('张三')}"
    puts "   包含13800138000: #{text.include?('13800138000')}"
    
  else
    puts "   错误信息: #{ocr_result[:error]}"
  end
  
rescue => e
  puts "   ❌ OCR文本提取测试失败: #{e.message}"
end

puts ""

# 3. 直接测试AI面单识别
puts "3. 直接测试AI面单识别..."
begin
  ai_service = AiParcelRecognitionService.new
  result = ai_service.recognize_parcel('/tmp/test_ai_enhanced.jpg')
  
  puts "   识别结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
  puts "   使用引擎: #{result[:engine]}"
  puts "   处理时间: #{result[:processing_time].round(2)}秒"
  
  if result[:success]
    data = result[:data]
    puts ""
    puts "   📋 识别结果详情:"
    puts "     运单号: #{data[:tracking_number] || '未识别'}"
    puts "     收件人: #{data[:recipient_name] || '未识别'}"
    puts "     手机号: #{data[:recipient_phone] || '未识别'}"
    puts "     快递公司: #{data[:courier_company] || '未识别'}"
    puts "     地址: #{data[:recipient_address] || '未识别'}"
    puts "     置信度: #{data[:confidence]}"
    
    if data[:reasoning]
      puts "     识别理由: #{data[:reasoning][0..200]}..."
    end
    
  else
    puts "   错误信息: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ AI面单识别测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 4. 测试实际面单图片
puts "4. 测试实际面单图片（如果有的话）..."
begin
  # 检查是否有实际面单图片
  actual_parcel_images = Dir.glob('/home/wjc/桌面/yizhan/public/parcels/*.jpg') + Dir.glob('/home/wjc/桌面/yizhan/public/parcels/*.png')
  
  if actual_parcel_images.any?
    puts "   找到 #{actual_parcel_images.size} 张实际面单图片"
    
    # 测试第一张图片
    test_image = actual_parcel_images.first
    puts "   测试图片: #{test_image}"
    
    ai_service = AiParcelRecognitionService.new
    result = ai_service.recognize_parcel(test_image)
    
    puts "   实际面单识别结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
    
    if result[:success]
      data = result[:data]
      puts "     运单号: #{data[:tracking_number] || '未识别'}"
      puts "     收件人: #{data[:recipient_name] || '未识别'}"
      puts "     手机号: #{data[:recipient_phone] || '未识别'}"
      puts "     快递公司: #{data[:courier_company] || '未识别'}"
    end
  else
    puts "   未找到实际面单图片，跳过测试"
  end
  
rescue => e
  puts "   ❌ 实际面单测试失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "建议:"
puts "- 如果OCR识别质量不佳，可以优化图片质量"
puts "- 确保图片清晰、文字大小适中"
puts "- 可以尝试不同的图片预处理方法"
puts "- AI识别依赖于OCR提取的文本质量"