#!/usr/bin/env ruby

# 调试前端响应问题 - 验证API返回格式
require_relative 'config/environment'

puts "=== 调试前端响应问题 ==="
puts ""

# 1. 模拟API调用并检查返回格式
puts "1. 模拟API调用并检查返回格式..."
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
    convert << '/tmp/debug_test.jpg'
  end
  
  # 模拟API控制器调用
  controller = Api::V1::AiController.new
  
  # 创建模拟的params对象
  class MockParams
    attr_reader :image
    
    def initialize(image_path)
      @image = File.open(image_path)
    end
  end
  
  # 调用ocr_parcel_public方法
  params = MockParams.new('/tmp/debug_test.jpg')
  
  # 使用反射调用私有方法
  result = controller.send(:ocr_parcel_public)
  
  puts "   API返回状态: #{result.status}"
  puts "   API返回内容类型: #{result.media_type}"
  
  # 解析JSON响应
  json_response = JSON.parse(result.body)
  
  puts "   JSON响应结构:"
  puts "     success: #{json_response['success']}"
  puts "     data字段存在: #{json_response.key?('data')}"
  
  if json_response['success'] && json_response['data']
    puts "    数据字段详情:"
    json_response['data'].each do |key, value|
      puts "      #{key}: #{value.inspect}"
    end
  else
    puts "    错误信息: #{json_response['error']}"
  end
  
rescue => e
  puts "   ❌ 模拟API调用失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 2. 检查前端期望的响应格式
puts "2. 检查前端期望的响应格式..."
begin
  frontend_code = File.read('/home/wjc/桌面/yizhan/app/javascript/packs/components/OcrUploader.vue')
  
  # 查找前端对响应数据的处理
  success_pattern = /if \(response\.data\.success\)/
  if frontend_code.match(success_pattern)
    puts "   ✅ 前端检查 response.data.success"
  else
    puts "   ❌ 前端未检查 response.data.success"
  end
  
  # 查找前端期望的数据结构
  data_pattern = /ocrResult\.value = response\.data\.data/
  if frontend_code.match(data_pattern)
    puts "   ✅ 前端期望 response.data.data"
  else
    puts "   ❌ 前端未使用 response.data.data"
  end
  
  # 检查前端错误处理
  error_pattern = /response\.data\.error/
  if frontend_code.match(error_pattern)
    puts "   ✅ 前端检查 response.data.error"
  else
    puts "   ❌ 前端未检查 response.data.error"
  end
  
rescue => e
  puts "   ❌ 检查前端代码失败: #{e.message}"
end

puts ""

# 3. 检查API控制器的render_json方法
puts "3. 检查API控制器的返回格式..."
begin
  base_controller_code = File.read('/home/wjc/桌面/yizhan/app/controllers/api/v1/base_controller.rb')
  
  # 查找render_json方法
  render_json_pattern = /def render_json/
  if base_controller_code.match(render_json_pattern)
    puts "   ✅ BaseController有render_json方法"
    
    # 提取render_json方法内容
    json_method = base_controller_code.match(/def render_json[\s\S]*?end/)
    if json_method
      puts "   render_json方法内容:"
      puts "     #{json_method[0].gsub(/\n/, '\n     ')}"
    end
  else
    puts "   ❌ BaseController没有render_json方法"
  end
  
rescue => e
  puts "   ❌ 检查BaseController失败: #{e.message}"
end

puts ""

# 4. 实际测试API端点
puts "4. 实际测试API端点..."
begin
  # 使用curl测试API端点
  test_command = "curl -X POST -F 'image=@/tmp/debug_test.jpg' http://localhost:3000/api/v1/ai/ocr_parcel_public"
  
  puts "   执行命令: #{test_command}"
  
  result = `#{test_command} 2>&1`
  
  if $?.success?
    puts "   ✅ API调用成功"
    
    # 解析响应
    begin
      json_response = JSON.parse(result)
      puts "   实际API响应:"
      puts "     success: #{json_response['success']}"
      
      if json_response['success']
        puts "     ✅ 后端返回success: true"
        puts "     数据字段:"
        json_response['data'].each do |key, value|
          puts "       #{key}: #{value.inspect}"
        end
      else
        puts "     ❌ 后端返回success: false"
        puts "     错误信息: #{json_response['error']}"
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
  puts "   ❌ 测试API端点失败: #{e.message}"
end

puts ""
puts "=== 调试完成 ==="
puts ""
puts "根据调试结果，前端显示'识别失败'的可能原因:"
puts "1. API返回的success字段不是true"
puts "2. 前端没有正确解析响应格式"
puts "3. 网络请求出现异常"
puts "4. 浏览器控制台可能有详细错误信息"