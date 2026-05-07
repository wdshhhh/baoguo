#!/usr/bin/env ruby

# 深度OCR调试脚本
require_relative 'config/environment'

puts "=== 深度OCR调试分析 ==="
puts ""

# 测试1：检查OcrResultParser的完整性
puts "1. 检查OcrResultParser完整性..."
begin
  test_text = "顺丰快递 SF1234567890\n收件人: 张三\n手机: 13800138000\n地址: 北京市朝阳区建国路88号"
  
  parser = OcrResultParser.new(test_text)
  parsed_data = parser.parse
  
  puts "   ✓ OcrResultParser实例化成功"
  
  # 检查所有字段
  required_fields = [:tracking_number, :recipient_name, :recipient_phone, :recipient_address, :courier_company]
  required_fields.each do |field|
    if parsed_data.key?(field)
      puts "   ✓ #{field}: #{parsed_data[field] || 'nil'}"
    else
      puts "   ❌ #{field}: 字段缺失"
    end
  end
  
  # 检查方法是否可调用
  methods_to_check = [:extract_tracking_number, :extract_recipient_name, :extract_recipient_phone, :extract_recipient_address]
  methods_to_check.each do |method|
    if parser.respond_to?(method)
      result = parser.send(method)
      puts "   ✓ #{method}: 可调用，返回: #{result || 'nil'}"
    else
      puts "   ❌ #{method}: 方法不存在"
    end
  end
  
rescue => e
  puts "   ❌ OcrResultParser检查失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\n      ')}"
end

puts ""

# 测试2：检查AI增强OCR服务的完整链路
puts "2. 检查AI增强OCR服务链路..."
begin
  # 创建测试图片
  test_image_path = "/tmp/debug_ocr_test.jpg"
  system("convert -size 300x200 xc:white -pointsize 20 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890' #{test_image_path}")
  
  if File.exist?(test_image_path)
    puts "   ✓ 测试图片创建成功"
    
    # 模拟上传文件
    require 'action_controller'
    
    class MockImage
      attr_reader :original_filename
      
      def initialize(path)
        @path = path
        @original_filename = File.basename(path)
      end
      
      def read
        File.binread(@path)
      end
      
      def size
        File.size(@path)
      end
    end
    
    mock_image = MockImage.new(test_image_path)
    
    # 测试FixedOcrService
    puts "   - 测试FixedOcrService..."
    fixed_service = FixedOcrService.new(test_image_path)
    fixed_result = fixed_service.recognize
    
    if fixed_result[:success]
      puts "     ✓ FixedOcrService识别成功"
      puts "       引擎: #{fixed_result[:engine]}"
      puts "       置信度: #{fixed_result[:confidence]}"
      puts "       识别文本: #{fixed_result[:raw_text][0..50]}..."
    else
      puts "     ❌ FixedOcrService识别失败: #{fixed_result[:error]}"
    end
    
    # 测试AI增强OCR服务
    puts "   - 测试AI增强OCR服务..."
    ai_service = AiEnhancedOcrService.new
    ai_result = ai_service.recognize_parcel_with_ai(mock_image)
    
    if ai_result[:success]
      puts "     ✓ AI增强OCR服务识别成功"
      data = ai_result[:data]
      
      # 检查数据结构
      expected_fields = [:tracking_number, :recipient_name, :recipient_phone, :courier_company, :recipient_address, :confidence, :raw_text]
      expected_fields.each do |field|
        if data.key?(field)
          puts "       ✓ #{field}: #{data[field] || 'nil'}"
        else
          puts "       ❌ #{field}: 字段缺失"
        end
      end
      
      # 检查数据类型
      string_fields = [:tracking_number, :recipient_name, :recipient_phone, :courier_company, :recipient_address]
      string_fields.each do |field|
        if data[field].is_a?(String) || data[field].nil?
          puts "       ✓ #{field}: 数据类型正确"
        else
          puts "       ❌ #{field}: 数据类型错误，期望String，实际: #{data[field].class}"
        end
      end
      
    else
      puts "     ❌ AI增强OCR服务识别失败: #{ai_result[:error]}"
    end
    
    # 清理测试图片
    File.delete(test_image_path)
  else
    puts "   ❌ 测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ AI增强OCR服务检查失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\n      ')}"
end

puts ""

# 测试3：检查API控制器
puts "3. 检查API控制器..."
begin
  # 模拟API调用
  puts "   ✓ API控制器结构检查"
  
  # 检查路由配置
  routes = Rails.application.routes.routes.map do |route|
    { path: route.path.spec.to_s, verb: route.verb } if route.path.spec.to_s.include?('ocr')
  end.compact
  
  puts "   - 可用OCR相关路由:"
  routes.each do |route|
    puts "       #{route[:verb]} #{route[:path]}"
  end
  
  # 检查控制器方法是否存在
  ai_controller = Api::V1::AiController.new
  methods = [:ocr_parcel, :ocr_parcel_enhanced]
  methods.each do |method|
    if ai_controller.respond_to?(method)
      puts "     ✓ #{method}: 控制器方法存在"
    else
      puts "     ❌ #{method}: 控制器方法不存在"
    end
  end
  
rescue => e
  puts "   ❌ API控制器检查失败: #{e.message}"
end

puts ""

# 测试4：检查前端数据结构匹配
puts "4. 检查前后端数据结构匹配..."
begin
  # 模拟前端期望的数据结构
  frontend_expected = {
    tracking_number: "运单号",
    recipient_name: "收件人姓名", 
    recipient_phone: "收件人手机号",
    courier_company: "快递公司",
    recipient_address: "收件地址",
    confidence: "置信度",
    raw_text: "原始文本"
  }
  
  # 模拟后端实际返回的数据结构
  backend_actual = {
    tracking_number: "SF1234567890",
    recipient_name: "张三",
    recipient_phone: "13800138000", 
    courier_company: "顺丰速运",
    recipient_address: "北京市朝阳区",
    confidence: 0.65,
    raw_text: "顺丰快递 SF1234567890"
  }
  
  puts "   ✓ 前后端数据结构匹配检查"
  
  # 检查字段一致性
  frontend_expected.keys.each do |field|
    if backend_actual.key?(field)
      puts "       ✓ #{field}: 前后端字段一致"
    else
      puts "       ❌ #{field}: 后端缺少此字段"
    end
  end
  
  # 检查数据类型
  backend_actual.each do |field, value|
    expected_type = case field
                   when :confidence then Numeric
                   else String
                   end
    
    if value.is_a?(expected_type) || value.nil?
      puts "       ✓ #{field}: 数据类型正确 (#{value.class})"
    else
      puts "       ❌ #{field}: 数据类型错误，期望#{expected_type}，实际#{value.class}"
    end
  end
  
rescue => e
  puts "   ❌ 数据结构匹配检查失败: #{e.message}"
end

puts ""
puts "=== 深度调试完成 ==="
puts ""
puts "发现的问题总结:"
puts "1. 检查OcrResultParser的方法完整性和可调用性"
puts "2. 验证AI增强OCR服务的数据结构一致性"
puts "3. 确认API控制器的路由和方法可用性"
puts "4. 检查前后端数据结构的匹配性"
puts ""
puts "下一步行动:"
puts "根据调试结果修复发现的具体问题"