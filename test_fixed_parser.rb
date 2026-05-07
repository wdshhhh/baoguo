#!/usr/bin/env ruby

# 测试修复后的OCR解析器
require_relative 'config/environment'

puts "=== 测试修复后的OCR解析器 ==="
puts ""

# 测试文本
TEST_TEXT = "顺丰快递 SF1234567890\n收件人: 张三\n手机: 13800138000\n地址: 北京市朝阳区建国路88号"

puts "测试文本:"
puts "```"
puts TEST_TEXT
puts "```"
puts ""

# 创建解析器实例
parser = OcrResultParser.new(TEST_TEXT)

puts "1. 修复后的解析结果:"
puts ""

begin
  parsed_data = parser.parse
  
  puts "   ✅ 完整解析成功"
  puts ""
  
  parsed_data.each do |field, value|
    status = value ? "✅" : "❌"
    puts "   #{status} #{field}: #{value || 'nil'}"
  end
  
  puts ""
  puts "2. 关键字段验证:"
  puts ""
  
  # 验证关键字段
  expected_values = {
    tracking_number: "SF1234567890",
    recipient_name: "张三", 
    recipient_phone: "13800138000",
    recipient_province: "北京",
    recipient_city: "北京市",
    recipient_address: "北京市朝阳区建国路88号",
    courier_company: "顺丰速运"
  }
  
  expected_values.each do |field, expected|
    actual = parsed_data[field]
    if actual == expected
      puts "   ✅ #{field}: 正确 (期望: #{expected}, 实际: #{actual})"
    else
      puts "   ❌ #{field}: 错误 (期望: #{expected}, 实际: #{actual})"
    end
  end
  
  # 计算准确率
  correct_count = expected_values.count { |field, expected| parsed_data[field] == expected }
  total_count = expected_values.size
  accuracy = (correct_count.to_f / total_count * 100).round(2)
  
  puts ""
  puts "3. 解析准确率: #{accuracy}% (#{correct_count}/#{total_count})"
  
  if accuracy >= 80
    puts "   ✅ 解析准确率良好，可以正常使用"
  else
    puts "   ❌ 解析准确率较低，需要进一步优化"
  end
  
rescue => e
  puts "   ❌ 解析失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\n      ')}"
end

puts ""
puts "=== 测试完成 ==="