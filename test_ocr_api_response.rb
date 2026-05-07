#!/usr/bin/env ruby

# 测试OCR API返回的数据格式
require_relative 'config/environment'

puts "=== 测试OCR API返回的数据格式 ==="
puts ""

# 创建测试图片
puts "1. 创建测试图片..."
require 'mini_magick'

image = MiniMagick::Tool::Convert.new do |convert|
  convert.size '600x400'
  convert.xc 'white'
  convert.font 'DejaVu-Sans'
  convert.pointsize 16
  convert.fill 'black'
  convert.gravity 'northwest'
  convert.annotate '+20+20', '顺丰速运'
  convert.annotate '+20+50', '运单号: SF1234567890'
  convert.annotate '+20+80', '收件人: 张三'
  convert.annotate '+20+110', '电话: 13800138000'
  convert.annotate '+20+140', '地址: 北京市朝阳区某某街道123号'
  convert << '/tmp/test_ocr_api.jpg'
end

puts "   测试图片创建成功: /tmp/test_ocr_api.jpg"
puts ""

# 测试AI增强OCR服务
puts "2. 测试AI增强OCR服务返回的数据格式..."
begin
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_ocr_api.jpg')
  
  puts "   服务返回结果:"
  puts "   成功: #{result[:success]}"
  
  if result[:success]
    puts "   数据字段:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
    
    puts ""
    puts "   前端期望的字段:"
    puts "     tracking_number: #{result[:data][:tracking_number]}"
    puts "     recipient_name: #{result[:data][:recipient_name]}"
    puts "     recipient_phone: #{result[:data][:recipient_phone]}"
    
    # 检查字段是否匹配
    required_fields = [:tracking_number, :recipient_name, :recipient_phone]
    missing_fields = required_fields.select { |field| result[:data][field].nil? }
    
    if missing_fields.empty?
      puts ""
      puts "   ✅ 所有必需字段都存在"
    else
      puts ""
      puts "   ❌ 缺少字段: #{missing_fields.join(', ')}"
    end
  else
    puts "   错误: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ 服务测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 测试API控制器
puts "3. 测试API控制器返回格式..."
begin
  require 'rack/test'
  
  # 模拟API调用
  image_file = File.open('/tmp/test_ocr_api.jpg', 'rb')
  
  # 创建模拟请求
  controller = Api::V1::AiController.new
  
  # 模拟params
  params = { image: image_file }
  
  # 调用方法
  result = controller.ocr_parcel_public
  
  puts "   API返回状态: #{result.status}"
  
  # 解析JSON响应
  json_response = JSON.parse(result.body)
  puts "   API返回数据:"
  puts "     success: #{json_response['success']}"
  
  if json_response['success']
    puts "     data字段:"
    json_response['data'].each do |key, value|
      puts "       #{key}: #{value.inspect}"
    end
  else
    puts "     error: #{json_response['error']}"
  end
  
  image_file.close
  
rescue => e
  puts "   ❌ API测试失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="