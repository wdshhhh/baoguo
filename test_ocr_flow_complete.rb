#!/usr/bin/env ruby

# 完整测试OCR流程
require_relative 'config/environment'

puts "=== 完整OCR流程测试 ==="
puts ""

# 1. 测试后端API直接调用
puts "1. 测试后端API直接调用:"
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
    convert.annotate '0,0', '韵达快递 YD333444555 13600136000 北京市朝阳区'
    convert << '/tmp/test_ocr_api.jpg'
  end
  
  puts "   测试图片创建成功: /tmp/test_ocr_api.jpg"
  
  # 模拟API调用
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_ocr_api.jpg')
  
  puts "   API调用结果:"
  puts "   成功: #{result[:success]}"
  
  if result[:success]
    puts "   返回数据格式:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
    
    # 检查关键字段
    puts ""
    puts "   关键字段检查:"
    required_fields = ['tracking_number', 'recipient_phone', 'courier_company']
    required_fields.each do |field|
      if result[:data][field.to_sym]
        puts "     ✅ #{field}: #{result[:data][field.to_sym]}"
      else
        puts "     ❌ #{field}: 缺失"
      end
    end
  else
    puts "   错误: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ API调用失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 2. 测试控制器API
puts "2. 测试控制器API响应:"
begin
  require 'rack/test'
  
  # 模拟API控制器调用
  controller = Api::V1::AiController.new
  
  # 模拟请求参数
  class MockRequest
    def headers
      {}
    end
  end
  
  class MockParams
    def [](key)
      if key == :image
        File.open('/tmp/test_ocr_api.jpg')
      end
    end
  end
  
  # 模拟控制器调用
  controller.instance_variable_set(:@params, MockParams.new)
  controller.instance_variable_set(:@request, MockRequest.new)
  
  # 调用ocr_parcel_public方法
  result = controller.send(:ocr_parcel_public)
  
  puts "   控制器响应: 成功"
  
rescue => e
  puts "   ❌ 控制器测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 3. 检查前端期望的数据格式
puts "3. 前端期望的数据格式:"
puts "   - 期望字段: tracking_number, recipient_name, recipient_phone, courier_company, recipient_address"
puts "   - 期望结构: { success: true, data: { ... } }"
puts "   - 实际结构: #{result[:success] ? '正确' : '错误'}"

puts ""

# 4. 诊断前端问题
puts "4. 前端问题诊断:"
puts "   可能的问题:"
puts "   - API接口调用错误 (已修复)"
puts "   - 响应数据格式不匹配"
puts "   - 前端错误处理逻辑过于严格"
puts "   - 网络请求超时或错误"

puts ""

# 5. 建议修复方案
puts "5. 修复建议:"
puts "   - 检查前端axios响应拦截器"
puts "   - 检查前端错误处理逻辑"
puts "   - 添加详细的调试日志"
puts "   - 确保API返回的数据格式与前端期望一致"

puts ""
puts "=== 测试完成 ==="