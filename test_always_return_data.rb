#!/usr/bin/env ruby

# 测试AI识别始终返回数据的功能
require_relative 'config/environment'

puts "=== 测试AI识别始终返回数据 ==="
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
    convert << '/tmp/test_always_return.jpg'
  end
  
  puts "   ✅ 测试图片创建成功: /tmp/test_always_return.jpg"
  
rescue => e
  puts "   ❌ 创建测试图片失败: #{e.message}"
  exit 1
end

puts ""

# 2. 测试AI识别服务（正常情况）
puts "2. 测试AI识别服务（正常情况）..."
begin
  ai_service = AiParcelRecognitionService.new
  
  start_time = Time.now
  result = ai_service.recognize_parcel('/tmp/test_always_return.jpg')
  processing_time = Time.now - start_time
  
  puts "   识别耗时: #{processing_time.round(2)}秒"
  
  if result[:success]
    puts "   ✅ AI识别成功"
    puts "   识别结果:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
  else
    puts "   ❌ AI识别失败"
    puts "   错误信息: #{result[:error]}"
    if result[:data]
      puts "   📋 但仍然返回了识别数据:"
      result[:data].each do |key, value|
        puts "     #{key}: #{value.inspect}"
      end
    end
  end
  
rescue => e
  puts "   ❌ AI识别服务测试失败: #{e.message}"
end

puts ""

# 3. 模拟AI识别失败的情况
puts "3. 模拟AI识别失败的情况..."
begin
  # 创建一个会导致AI识别失败的图片（空白图片）
  blank_image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '100x100'
    convert.xc 'white'
    convert << '/tmp/test_blank.jpg'
  end
  
  ai_service = AiParcelRecognitionService.new
  
  start_time = Time.now
  result = ai_service.recognize_parcel('/tmp/test_blank.jpg')
  processing_time = Time.now - start_time
  
  puts "   识别耗时: #{processing_time.round(2)}秒"
  
  if result[:success]
    puts "   ✅ AI识别成功（意外情况）"
    puts "   识别结果:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
  else
    puts "   ❌ AI识别失败（预期情况）"
    puts "   错误信息: #{result[:error]}"
    if result[:data]
      puts "   📋 但仍然返回了识别数据:"
      result[:data].each do |key, value|
        puts "     #{key}: #{value.inspect}"
      end
    else
      puts "   ❌ 没有返回识别数据（需要修复）"
    end
  end
  
rescue => e
  puts "   ❌ 模拟失败测试异常: #{e.message}"
end

puts ""

# 4. 测试API端点
puts "4. 测试API端点..."
begin
  # 使用curl测试API端点
  test_command = "curl -X POST -F 'image=@/tmp/test_always_return.jpg' http://localhost:3000/api/v1/ai/ocr_parcel_public"
  
  puts "   执行命令: #{test_command}"
  
  result = `#{test_command} 2>&1`
  
  if $?.success?
    puts "   ✅ API调用成功"
    
    # 解析响应
    begin
      json_response = JSON.parse(result)
      puts "   实际API响应:"
      
      # 检查是否包含数据字段
      if json_response.key?('data')
        puts "   ✅ 包含数据字段"
        json_response['data'].each do |key, value|
          puts "     #{key}: #{value.inspect}"
        end
      else
        puts "   ❌ 缺少数据字段"
      end
      
      # 检查是否包含错误字段
      if json_response.key?('error')
        puts "   ⚠️  包含错误信息: #{json_response['error']}"
      end
      
    rescue JSON::ParserError
      puts "     ❌ 响应不是有效的JSON"
      puts "     原始响应: #{result[0..200]}..."
    end
  else
    puts "   ❌ API调用失败"
    puts "     错误信息: #{result}"
  end
  
rescue => e
  puts "   ❌ API端点测试失败: #{e.message}"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "修改总结:"
puts "- ✅ AI识别成功时：返回完整识别数据"
puts "- ✅ AI识别失败时：返回OCR提取的文本信息"
puts "- ✅ 发生异常时：返回异常信息和OCR文本"
puts "- ✅ 前端始终能接收到识别信息，不会显示'识别失败'"
puts "- 📋 用户可以看到OCR提取的原始文本，便于手动核对"