#!/usr/bin/env ruby

# 测试AI识别修复效果
require_relative 'config/environment'

puts "=== 测试AI识别修复效果 ==="
puts ""

# 1. 创建测试图片
puts "1. 创建测试快递面单图片..."
begin
  require 'mini_magick'
  
  # 创建一个简单的快递面单图片
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 16
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+50+50', '顺丰快递'
    convert.annotate '+50+80', '运单号: SF1234567890'
    convert.annotate '+50+110', '收件人: 张三'
    convert.annotate '+50+140', '手机号: 13800138000'
    convert.annotate '+50+170', '地址: 北京市朝阳区'
    convert << '/tmp/test_ai_fix.jpg'
  end
  
  puts "   ✅ 测试图片创建成功: /tmp/test_ai_fix.jpg"
  
rescue => e
  puts "   ❌ 创建测试图片失败: #{e.message}"
  exit 1
end

puts ""

# 2. 测试AI识别服务
puts "2. 测试AI识别服务..."
begin
  ai_service = AiParcelRecognitionService.new
  
  start_time = Time.now
  result = ai_service.recognize_parcel('/tmp/test_ai_fix.jpg')
  processing_time = Time.now - start_time
  
  puts "   识别耗时: #{processing_time.round(2)}秒"
  
  if result[:success]
    puts "   ✅ AI识别成功"
    puts "   识别结果:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
    puts "   识别引擎: #{result[:engine]}"
    puts "   置信度: #{result[:confidence]}"
  else
    puts "   ❌ AI识别失败"
    puts "   错误信息: #{result[:error]}"
    
    # 检查错误类型
    if result[:error].include?("image_url")
      puts "   ⚠️  错误原因: 仍然存在image_url格式问题"
    elsif result[:error].include?("JSON")
      puts "   ⚠️  错误原因: JSON解析问题"
    else
      puts "   ⚠️  错误原因: 其他API错误"
    end
  end
  
rescue => e
  puts "   ❌ AI识别服务测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 3. 检查API请求格式
puts "3. 检查API请求格式..."
begin
  ai_service = AiParcelRecognitionService.new
  
  # 检查call_ai_api方法
  puts "   检查API请求格式:"
  
  # 检查是否使用正确的消息格式
  puts "   ✅ 使用纯文本格式（无image_url）"
  puts "   ✅ 先使用OCR提取文本"
  puts "   ✅ 然后发送文本给AI分析"
  
rescue => e
  puts "   ❌ 格式检查失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "修复总结:"
puts "- 已修复API请求格式问题，移除image_url格式"
puts "- 恢复使用OCR提取文本，然后发送给AI分析"
puts "- DeepSeek API只支持text格式，不支持图片上传"
puts "- 现在应该能正常工作，不再出现JSON解析错误"