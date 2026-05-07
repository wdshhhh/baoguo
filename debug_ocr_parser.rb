#!/usr/bin/env ruby

# 调试OCR结果解析器问题
require_relative 'config/environment'

puts "=== 调试OCR结果解析器问题 ==="
puts ""

# 模拟OCR识别到的原始文本（根据您的日志）
raw_text = "YD333444555 13600136000"
puts "1. 原始OCR识别文本:"
puts "   #{raw_text.inspect}"
puts ""

# 测试OCR结果解析器
puts "2. 测试OCR结果解析器:"
begin
  parser = OcrResultParser.new(raw_text)
  parsed_data = parser.parse
  
  puts "   解析结果:"
  parsed_data.each do |key, value|
    puts "     #{key}: #{value.inspect}"
  end
  
  # 检查关键字段是否被正确提取
  puts ""
  puts "3. 关键字段提取检查:"
  
  if parsed_data[:tracking_number]
    puts "   ✅ 运单号提取成功: #{parsed_data[:tracking_number]}"
  else
    puts "   ❌ 运单号提取失败"
    
    # 手动测试运单号提取逻辑
    puts "   🔍 手动测试运单号提取:"
    patterns = [
      /(?:运单号|单号|Tracking|Tracking.*?No)[：:\s]*([A-Z0-9]{10,20})/i,
      /\b(SF|ZT|YT|JD|EMS)[A-Z0-9]{8,18}\b/i,
      /\b([0-9]{12,18})\b/
    ]
    
    patterns.each_with_index do |pattern, i|
      match = raw_text.match(pattern)
      if match
        puts "     模式#{i+1}匹配: #{match[1]}"
      else
        puts "     模式#{i+1}不匹配"
      end
    end
  end
  
  if parsed_data[:recipient_phone]
    puts "   ✅ 手机号提取成功: #{parsed_data[:recipient_phone]}"
  else
    puts "   ❌ 手机号提取失败"
    
    # 手动测试手机号提取逻辑
    puts "   🔍 手动测试手机号提取:"
    phone_patterns = [
      /(?:电话|手机|Phone|Mobile)[：:\s]*(\d{11})/i,
      /\b(1[3-9]\d{9})\b/
    ]
    
    phone_patterns.each_with_index do |pattern, i|
      match = raw_text.match(pattern)
      if match
        puts "     模式#{i+1}匹配: #{match[1]}"
      else
        puts "     模式#{i+1}不匹配"
      end
    end
  end
  
  if parsed_data[:recipient_name]
    puts "   ✅ 收件人姓名提取成功: #{parsed_data[:recipient_name]}"
  else
    puts "   ❌ 收件人姓名提取失败 (正常，文本中无姓名)"
  end
  
  if parsed_data[:courier_company]
    puts "   ✅ 快递公司提取成功: #{parsed_data[:courier_company]}"
  else
    puts "   ❌ 快递公司提取失败"
    
    # 根据运单号推断快递公司
    puts "   🔍 根据运单号推断快递公司:"
    if parsed_data[:tracking_number]
      tracking = parsed_data[:tracking_number]
      courier = case tracking[0..1]
                when "SF" then "顺丰"
                when "YT" then "圆通"
                when "ZT" then "中通"
                when "YD" then "韵达"
                when "ST" then "申通"
                when "JD" then "京东"
                when "DB" then "德邦"
                else "未知"
                end
      puts "     推断结果: #{courier}"
    end
  end
  
rescue => e
  puts "   ❌ OCR解析器错误: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 测试AI增强OCR服务
puts "4. 测试AI增强OCR服务:"
begin
  # 创建一个测试图片
  require 'mini_magick'
  
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x300'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 16
    convert.fill 'black'
    convert.gravity 'center'
    convert.annotate '0,0', '韵达快递 YD333444555 13600136000'
    convert << '/tmp/test_ocr_debug.jpg'
  end
  
  puts "   测试图片创建成功: /tmp/test_ocr_debug.jpg"
  
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_ocr_debug.jpg')
  
  puts "   AI增强OCR服务结果:"
  puts "   成功: #{result[:success]}"
  
  if result[:success]
    puts "   返回数据:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
  else
    puts "   错误: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ AI增强OCR服务测试失败: #{e.message}"
end

puts ""
puts "=== 调试完成 ==="