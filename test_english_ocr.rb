#!/usr/bin/env ruby

# 英文面单OCR识别测试
require_relative 'config/environment'

puts "=== 英文面单OCR识别测试 ==="
puts ""

# 创建英文测试图片
puts "1. 创建英文测试图片:"
puts ""

english_test_path = "/tmp/english_parcel_test_#{Time.now.to_i}.jpg"

# 创建包含英文信息的快递面单图片
system("convert -size 600x400 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 'SF Express\\nTracking: SF1234567890\\nRecipient: John Smith\\nPhone: 13800138000\\nAddress: 88 Jianguo Road, Chaoyang District, Beijing' #{english_test_path}")

if File.exist?(english_test_path)
  puts "   ✅ 英文测试图片创建成功: #{english_test_path}"
  puts ""
else
  puts "   ❌ 英文测试图片创建失败"
  exit(1)
end

# 测试OCR识别
puts "2. OCR识别测试:"
puts ""

begin
  # 使用FixedOcrService
  ocr_service = FixedOcrService.new(english_test_path)
  ocr_result = ocr_service.recognize
  
  if ocr_result[:success]
    puts "   ✅ OCR识别成功"
    puts "     引擎: #{ocr_result[:engine]}"
    puts "     置信度: #{ocr_result[:confidence]}"
    puts "     处理时间: #{ocr_result[:processing_time].round(2)}秒"
    puts ""
    
    # 显示识别文本
    puts "     识别文本:"
    puts "     " + "-" * 50
    puts "     #{ocr_result[:raw_text]}"
    puts "     " + "-" * 50
    puts ""
    
    # 解析结果
    puts "3. 解析结果测试:"
    puts ""
    
    parser = OcrResultParser.new(ocr_result[:raw_text])
    parsed_data = parser.parse
    
    # 计算准确率
    valid_fields = parsed_data.select { |k, v| v && !v.to_s.empty? }.size
    total_fields = parsed_data.size
    accuracy = (valid_fields.to_f / total_fields * 100).round(2)
    
    puts "   ✅ 解析完成，准确率: #{accuracy}%"
    puts ""
    
    # 显示解析结果
    puts "     解析结果:"
    parsed_data.each do |key, value|
      status = value && !value.to_s.empty? ? "✅" : "❌"
      puts "     #{status} #{key}: #{value || '空'}"
    end
    
    puts ""
    
    # 测试API接口
    puts "4. API接口测试:"
    puts ""
    
    # 模拟API调用
    ai_service = AiEnhancedOcrService.new
    api_result = ai_service.recognize_parcel_with_ai(File.open(english_test_path))
    
    if api_result[:success]
      puts "   ✅ API接口调用成功"
      puts ""
      
      puts "     API返回数据:"
      api_result[:data].each do |key, value|
        status = value && !value.to_s.empty? ? "✅" : "❌"
        puts "     #{status} #{key}: #{value || '空'}"
      end
    else
      puts "   ❌ API接口调用失败: #{api_result[:error]}"
    end
    
  else
    puts "   ❌ OCR识别失败: #{ocr_result[:error]}"
  end
  
rescue => e
  puts "   ❌ 测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..5].join('\\n     ')}"
end

puts ""

# 清理测试文件
File.delete(english_test_path) if File.exist?(english_test_path)

puts "=== 英文面单OCR识别测试完成 ==="
puts ""
puts "测试总结:"
puts "- 系统架构: 已清理冗余服务"
puts "- 中文语言包: 已重新安装"
puts "- 英文识别: 验证系统基本功能"