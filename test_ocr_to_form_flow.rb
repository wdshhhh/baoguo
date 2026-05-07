#!/usr/bin/env ruby

# 测试OCR识别到表单填充的完整流程
require_relative 'config/environment'

puts "=== 测试OCR识别到表单填充的完整流程 ==="
puts ""

# 1. 创建测试图片
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
  convert << '/tmp/test_ocr_flow.jpg'
end

puts "   测试图片创建成功: /tmp/test_ocr_flow.jpg"
puts ""

# 2. 测试后端OCR服务
puts "2. 测试后端OCR服务..."
begin
  ai_service = AiEnhancedOcrService.new
  result = ai_service.recognize_parcel_with_ai('/tmp/test_ocr_flow.jpg')
  
  puts "   后端OCR服务结果:"
  puts "   成功: #{result[:success]}"
  
  if result[:success]
    puts "   识别数据:"
    result[:data].each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
    
    # 检查字段是否完整
    required_fields = [:tracking_number, :recipient_name, :recipient_phone]
    missing_fields = required_fields.select { |field| result[:data][field].nil? }
    
    if missing_fields.empty?
      puts "   ✅ 所有必需字段都存在"
    else
      puts "   ❌ 缺少字段: #{missing_fields.join(', ')}"
    end
  else
    puts "   ❌ OCR识别失败: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ 后端OCR服务测试失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 3. 模拟前端表单填充
puts "3. 模拟前端表单填充逻辑..."

# 模拟前端表单数据结构
new_package = {
  tracking_number: "",
  recipient_name: "",
  recipient_phone: "",
  courier_company: "",
  recipient_address: "",
  storage_location: "",
  package_type: "",
  weight: "",
  remark: ""
}

puts "   填充前表单数据:"
new_package.each { |k, v| puts "     #{k}: #{v.inspect}" }
puts ""

# 模拟OCR识别结果
ocr_data = {
  tracking_number: "SF1234567890",
  recipient_name: "张三",
  recipient_phone: "13800138000",
  courier_company: "顺丰速运",
  recipient_address: "北京市朝阳区某某街道123号",
  confidence: 0.85,
  raw_text: "顺丰速运 运单号: SF1234567890 收件人: 张三 电话: 13800138000 地址: 北京市朝阳区某某街道123号"
}

puts "   OCR识别结果:"
ocr_data.each { |k, v| puts "     #{k}: #{v.inspect}" }
puts ""

# 模拟智能填充逻辑
puts "4. 执行智能表单填充..."

# 运单号处理
if ocr_data[:tracking_number]
  new_package[:tracking_number] = ocr_data[:tracking_number]
  puts "   ✅ 运单号填充: #{ocr_data[:tracking_number]}"
end

# 收件人信息处理
if ocr_data[:recipient_name]
  new_package[:recipient_name] = ocr_data[:recipient_name]
  puts "   ✅ 收件人姓名填充: #{ocr_data[:recipient_name]}"
end

if ocr_data[:recipient_phone]
  # 手机号格式标准化
  formatted_phone = ocr_data[:recipient_phone].gsub(/[^\d]/, '')
  new_package[:recipient_phone] = formatted_phone
  puts "   ✅ 手机号填充: #{formatted_phone}"
end

# 快递公司信息
if ocr_data[:courier_company]
  new_package[:courier_company] = ocr_data[:courier_company]
  puts "   ✅ 快递公司填充: #{ocr_data[:courier_company]}"
end

# 地址信息
if ocr_data[:recipient_address]
  new_package[:recipient_address] = ocr_data[:recipient_address]
  puts "   ✅ 地址填充: #{ocr_data[:recipient_address]}"
end

# 备注信息
if ocr_data[:raw_text]
  confidence = ocr_data[:confidence] || '未知'
  new_package[:remark] = "OCR识别结果（置信度: #{confidence}）: #{ocr_data[:raw_text][0..100]}..."
  puts "   ✅ 备注信息填充"
end

puts ""
puts "   填充后表单数据:"
new_package.each { |k, v| puts "     #{k}: #{v.inspect}" }
puts ""

# 5. 检查填充效果
filled_fields = new_package.select { |k, v| !v.to_s.empty? }.keys
puts "5. 填充效果检查:"
puts "   已填充字段数: #{filled_fields.size}"
puts "   已填充字段: #{filled_fields.join(', ')}"

if filled_fields.size >= 3
  puts "   ✅ 表单填充成功！至少填充了3个关键字段"
else
  puts "   ❌ 表单填充不完整，需要检查OCR识别质量"
end

puts ""
puts "=== 测试完成 ==="
puts ""
puts "💡 问题诊断:"
puts "- 如果后端OCR识别失败，需要检查图片处理逻辑"
puts "- 如果后端识别成功但前端未填充，需要检查数据传递流程"
puts "- 如果前端填充逻辑有问题，需要检查smartFillPackageForm方法"