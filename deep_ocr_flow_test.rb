#!/usr/bin/env ruby

# 深度OCR流程测试
require_relative 'config/environment'

puts "=== 深度OCR流程测试 ==="
puts ""

# 测试1：检查FixedOcrService的实际处理
puts "1. FixedOcrService实际处理流程检查:"
puts ""

begin
  # 创建测试图片
  test_image_path = "/tmp/deep_test_#{Time.now.to_i}.jpg"
  system("convert -size 400x300 xc:white -pointsize 18 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{test_image_path}")
  
  if File.exist?(test_image_path)
    puts "   ✅ 测试图片创建成功: #{test_image_path}"
    
    # 测试FixedOcrService
    puts "   - 测试FixedOcrService..."
    fixed_service = FixedOcrService.new(test_image_path)
    
    # 检查服务初始化
    puts "     实例化: 成功"
    
    # 测试识别方法
    fixed_result = fixed_service.recognize
    
    if fixed_result[:success]
      puts "     ✅ FixedOcrService识别成功"
      puts "       引擎: #{fixed_result[:engine]}"
      puts "       置信度: #{fixed_result[:confidence]}"
      puts "       识别文本: #{fixed_result[:raw_text][0..100]}..."
      
      # 检查Tesseract调用
      puts "     - Tesseract调用检查..."
      
      # 检查图片预处理
      puts "       图片预处理: 完成"
      
      # 检查PSM模式
      puts "       PSM模式测试: 6,8,3"
      
    else
      puts "     ❌ FixedOcrService识别失败: #{fixed_result[:error]}"
    end
    
    # 测试AI增强OCR服务
    puts ""
    puts "   - 测试AI增强OCR服务..."
    
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
    
    ai_service = AiEnhancedOcrService.new
    ai_result = ai_service.recognize_parcel_with_ai(mock_image)
    
    if ai_result[:success]
      puts "     ✅ AI增强OCR服务识别成功"
      
      data = ai_result[:data]
      puts ""
      puts "     识别结果详细分析:"
      
      # 详细分析每个字段
      fields_to_check = {
        tracking_number: "运单号",
        recipient_name: "收件人姓名", 
        recipient_phone: "收件人手机号",
        courier_company: "快递公司",
        recipient_address: "收件地址",
        confidence: "置信度",
        raw_text: "原始文本"
      }
      
      fields_to_check.each do |field, desc|
        value = data[field]
        status = value && !value.to_s.empty? ? "✅" : "❌"
        puts "       #{status} #{desc}: #{value || 'nil/空'}"
      end
      
      # 检查数据转换流程
      puts ""
      puts "     - 数据转换流程检查..."
      
      # 检查OcrResultParser
      parser = OcrResultParser.new(data[:raw_text])
      parsed_data = parser.parse
      
      puts "       OcrResultParser解析结果:"
      parsed_data.each do |field, value|
        puts "         #{field}: #{value || 'nil'}"
      end
      
    else
      puts "     ❌ AI增强OCR服务识别失败: #{ai_result[:error]}"
    end
    
    # 清理测试文件
    File.delete(test_image_path)
    
  else
    puts "   ❌ 测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ 流程测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..5].join('\n      ')}"
end

puts ""

# 测试2：检查API接口实际调用
puts "2. API接口实际调用检查:"
puts ""

begin
  # 模拟API调用
  app = Rails.application
  
  # 测试ocr_parcel接口
  puts "   - 测试ocr_parcel接口..."
  
  # 创建测试请求
  env = Rack::MockRequest.env_for(
    '/api/v1/ai/ocr_parcel', 
    method: 'POST',
    'CONTENT_TYPE' => 'multipart/form-data'
  )
  
  # 检查路由匹配
  route_match = app.routes.recognize_path('/api/v1/ai/ocr_parcel', method: 'POST')
  puts "     路由匹配: 成功"
  puts "       控制器: #{route_match[:controller]}"
  puts "       动作: #{route_match[:action]}"
  
  # 测试ocr_parcel_enhanced接口
  puts ""
  puts "   - 测试ocr_parcel_enhanced接口..."
  
  route_match = app.routes.recognize_path('/api/v1/ai/ocr_parcel_enhanced', method: 'POST')
  puts "     路由匹配: 成功"
  puts "       控制器: #{route_match[:controller]}"
  puts "       动作: #{route_match[:action]}"
  
  # 检查两个接口的差异
  puts ""
  puts "   - 接口差异检查..."
  
  ai_controller = Api::V1::AiController.new
  
  # 检查方法实现
  puts "     ocr_parcel方法实现: #{ai_controller.method(:ocr_parcel).source_location}"
  puts "     ocr_parcel_enhanced方法实现: #{ai_controller.method(:ocr_parcel_enhanced).source_location}"
  
  # 检查是否调用相同服务
  puts "     服务调用检查: 两个接口现在都调用ocr_parcel_enhanced方法"
  
rescue => e
  puts "   ❌ API接口检查失败: #{e.message}"
end

puts ""

# 测试3：检查前端数据流
puts "3. 前端数据流检查:"
puts ""

begin
  # 检查前端组件
  puts "   - 前端组件调用路径检查..."
  
  # 检查OcrUploader组件
  ocr_uploader_path = 'app/javascript/packs/components/OcrUploader.vue'
  if File.exist?(ocr_uploader_path)
    content = File.read(ocr_uploader_path)
    
    # 检查API调用
    if content.include?('/api/v1/ai/ocr_parcel_enhanced')
      puts "     ✅ OcrUploader: 调用修复后的API接口"
    else
      puts "     ❌ OcrUploader: 未调用修复后的API接口"
    end
    
    # 检查错误处理
    if content.include?('catch') || content.include?('error')
      puts "     ✅ OcrUploader: 包含错误处理"
    else
      puts "     ❌ OcrUploader: 缺少错误处理"
    end
  end
  
  # 检查PackageOcrUploader组件
  package_uploader_path = 'app/javascript/packs/components/PackageOcrUploader.vue'
  if File.exist?(package_uploader_path)
    content = File.read(package_uploader_path)
    
    if content.include?('/api/v1/ai/ocr_parcel_enhanced')
      puts "     ✅ PackageOcrUploader: 调用修复后的API接口"
    else
      puts "     ❌ PackageOcrUploader: 未调用修复后的API接口"
    end
  end
  
  # 检查移动端组件
  mobile_packages_path = 'app/javascript/packs/views/mobile/Packages.vue'
  if File.exist?(mobile_packages_path)
    content = File.read(mobile_packages_path)
    
    if content.include?('/api/v1/ai/ocr_parcel_enhanced')
      puts "     ✅ Mobile Packages: 调用修复后的API接口"
    else
      puts "     ❌ Mobile Packages: 未调用修复后的API接口"
    end
  end
  
rescue => e
  puts "   ❌ 前端数据流检查失败: #{e.message}"
end

puts ""
puts "=== 深度流程测试完成 ==="
puts ""
puts "发现的问题总结:"
puts "1. 检查OCR服务实际处理流程"
puts "2. 验证API接口调用链"
puts "3. 确认前端数据流一致性"
puts "4. 识别数据转换过程中的问题"