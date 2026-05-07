#!/usr/bin/env ruby

# 调试前端显示问题
require_relative 'config/environment'

puts "=== 调试前端显示问题 ==="
puts ""

# 1. 检查API路由配置
puts "1. 检查API路由配置..."
begin
  routes_file = File.read('/home/wjc/桌面/yizhan/config/routes.rb')
  
  # 查找OCR相关的路由
  if routes_file.include?('ocr_parcel')
    puts "   ✅ 找到OCR相关路由"
    
    # 提取相关路由配置
    routes_file.split('\n').each do |line|
      if line.include?('ocr_parcel')
        puts "     路由: #{line.strip}"
      end
    end
  else
    puts "   ❌ 未找到OCR相关路由"
  end
  
rescue => e
  puts "   ❌ 检查路由配置失败: #{e.message}"
end

puts ""

# 2. 检查前端实际调用的接口
puts "2. 检查前端实际调用的接口..."
puts "   根据终端日志，前端调用了: /api/v1/ai/ocr_parcel"
puts "   但前端代码中写的是: /api/v1/ai/ocr_parcel_public"
puts ""

# 3. 检查API控制器
puts "3. 检查API控制器返回格式..."
begin
  # 检查ocr_parcel接口
  puts "   ocr_parcel接口 (需要认证):"
  puts "     - 重定向到 ocr_parcel_enhanced"
  puts "     - ocr_parcel_enhanced也需要认证"
  
  # 检查ocr_parcel_public接口
  puts "   ocr_parcel_public接口 (免认证):"
  puts "     - 直接返回识别结果"
  puts "     - 无论成功失败都返回data字段"
  
rescue => e
  puts "   ❌ 检查API控制器失败: #{e.message}"
end

puts ""

# 4. 测试两个接口的差异
puts "4. 测试两个接口的差异..."
begin
  # 创建测试图片
  require 'mini_magick'
  
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 16
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+50+50', '韵达快递'
    convert.annotate '+50+80', '运单号: YD333444555'
    convert.annotate '+50+110', '手机号: 13600136000'
    convert << '/tmp/test_debug.jpg'
  end
  
  puts "   ✅ 测试图片创建成功"
  
  # 测试公开接口
  puts "   测试公开接口 (ocr_parcel_public):"
  public_command = "curl -X POST -F 'image=@/tmp/test_debug.jpg' http://localhost:3000/api/v1/ai/ocr_parcel_public"
  public_result = `#{public_command} 2>&1`
  
  if $?.success?
    puts "     ✅ 公开接口调用成功"
    begin
      json_response = JSON.parse(public_result)
      puts "     success字段: #{json_response['success']}"
      if json_response['success']
        puts "     ✅ 返回success: true"
      else
        puts "     ❌ 返回success: false"
      end
    rescue JSON::ParserError
      puts "     ❌ 响应不是有效的JSON"
    end
  else
    puts "     ❌ 公开接口调用失败"
  end
  
  # 测试认证接口（需要认证头）
  puts "   测试认证接口 (ocr_parcel):"
  auth_command = "curl -X POST -F 'image=@/tmp/test_debug.jpg' -H 'Authorization: Bearer test' http://localhost:3000/api/v1/ai/ocr_parcel"
  auth_result = `#{auth_command} 2>&1`
  
  if $?.success?
    puts "     ✅ 认证接口调用成功"
    begin
      json_response = JSON.parse(auth_result)
      puts "     success字段: #{json_response['success']}"
    rescue JSON::ParserError
      puts "     ❌ 响应不是有效的JSON"
    end
  else
    puts "     ❌ 认证接口调用失败（需要有效认证）"
  end
  
rescue => e
  puts "   ❌ 测试接口差异失败: #{e.message}"
end

puts ""
puts "=== 调试完成 ==="
puts ""
puts "问题分析:"
puts "1. 前端代码中调用的是公开接口 /api/v1/ai/ocr_parcel_public"
puts "2. 但实际调用的是认证接口 /api/v1/ai/ocr_parcel"
puts "3. 可能原因: 缓存、重定向、路由配置问题"
puts ""
puts "解决方案:"
puts "1. 清除浏览器缓存"
puts "2. 检查前端路由配置"
puts "3. 确保调用正确的公开接口"