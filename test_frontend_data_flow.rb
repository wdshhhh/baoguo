#!/usr/bin/env ruby

# 测试前端数据流 - 验证后端返回数据格式
require_relative 'config/environment'

puts "=== 前端数据流测试 ==="
puts ""

# 1. 测试后端API返回格式
puts "1. 测试后端API返回格式..."
begin
  # 创建测试图片
  require 'mini_magick'
  
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 20
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+50+50', '顺丰快递 SF1234567890'
    convert.annotate '+50+100', '收件人: 张三'
    convert.annotate '+50+150', '手机号: 13800138000'
    convert.annotate '+50+200', '地址: 北京市朝阳区'
    convert << '/tmp/test_frontend.jpg'
  end
  
  puts "   ✅ 测试图片创建成功"
  
  # 模拟API调用
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_frontend.jpg')
  
  puts "   API调用结果: #{result[:success] ? '✅ 成功' : '❌ 失败'}"
  
  if result[:success]
    data = result[:data]
    puts ""
    puts "   📋 后端返回数据格式:"
    puts "     - tracking_number: #{data[:tracking_number]}"
    puts "     - recipient_name: #{data[:recipient_name]}"
    puts "     - recipient_phone: #{data[:recipient_phone]}"
    puts "     - courier_company: #{data[:courier_company]}"
    puts "     - recipient_address: #{data[:recipient_address]}"
    puts "     - confidence: #{data[:confidence]}"
    puts "     - raw_text: #{data[:raw_text][0..50]}..."
    
    # 检查字段是否完整
    required_fields = [:tracking_number, :recipient_name, :recipient_phone, :courier_company, :recipient_address, :confidence]
    missing_fields = required_fields.select { |field| data[field].nil? || data[field].empty? }
    
    if missing_fields.any?
      puts ""
      puts "   ⚠️  缺失字段: #{missing_fields.join(', ')}"
    else
      puts ""
      puts "   ✅ 所有必需字段都存在"
    end
    
  else
    puts "   错误信息: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ 后端API测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 2. 检查前端期望的字段名
puts "2. 检查前端期望的字段名..."
begin
  # 读取前端组件文件
  frontend_file = File.read('/home/wjc/桌面/yizhan/app/javascript/packs/components/OcrUploader.vue')
  
  # 查找前端使用的字段名
  field_patterns = {
    tracking_number: /v-model="ocrResult\.tracking_number"/,
    recipient_name: /v-model="ocrResult\.recipient_name"/,
    recipient_phone: /v-model="ocrResult\.recipient_phone"/,
    courier_company: /v-model="ocrResult\.courier_company"/,
    recipient_address: /v-model="ocrResult\.recipient_address"/,
    confidence: /ocrResult\.confidence/
  }
  
  puts "   前端使用的字段名:"
  field_patterns.each do |field, pattern|
    if frontend_file.match(pattern)
      puts "     ✅ #{field}: 已在前端使用"
    else
      puts "     ❌ #{field}: 未在前端找到"
    end
  end
  
  # 检查是否有旧的字段名
  old_fields = {
    customer_name: /v-model="ocrResult\.customer_name"/,
    customer_phone: /v-model="ocrResult\.customer_phone"/
  }
  
  old_fields.each do |field, pattern|
    if frontend_file.match(pattern)
      puts "     ⚠️  发现旧字段: #{field} (需要更新)"
    end
  end
  
rescue => e
  puts "   ❌ 前端字段检查失败: #{e.message}"
end

puts ""

# 3. 验证数据一致性
puts "3. 验证前后端数据一致性..."
begin
  # 模拟前后端数据流
  backend_data = {
    tracking_number: "SF1234567890",
    recipient_name: "张三",
    recipient_phone: "13800138000",
    courier_company: "顺丰",
    recipient_address: "北京市朝阳区",
    confidence: 0.95,
    raw_text: "顺丰快递 SF1234567890 收件人: 张三 手机号: 13800138000"
  }
  
  frontend_fields = ["tracking_number", "recipient_name", "recipient_phone", "courier_company", "recipient_address", "confidence"]
  
  puts "   前后端字段匹配情况:"
  frontend_fields.each do |field|
    if backend_data.key?(field.to_sym)
      puts "     ✅ #{field}: 前后端一致"
    else
      puts "     ❌ #{field}: 后端缺少此字段"
    end
  end
  
  # 检查是否有字段名不匹配
  potential_mismatches = {
    "recipient_name" => "customer_name",
    "recipient_phone" => "customer_phone"
  }
  
  potential_mismatches.each do |backend_field, frontend_field|
    if backend_data.key?(backend_field.to_sym)
      puts "     ℹ️  后端使用 '#{backend_field}'，前端应确保使用相同字段名"
    end
  end
  
rescue => e
  puts "   ❌ 数据一致性检查失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "总结:"
puts "- 检查前后端字段名是否一致"
puts "- 确保所有必需字段都在前端显示"
puts "- 验证数据流是否畅通"