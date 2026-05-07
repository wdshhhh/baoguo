#!/usr/bin/env ruby

# 详细OCR调试脚本
require_relative 'config/environment'

puts "=== 详细OCR调试分析 ==="
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

puts "1. 检查文本预处理..."
puts "   原始文本行数: #{parser.instance_variable_get(:@lines).size}"
puts "   预处理后行数: #{parser.instance_variable_get(:@lines).size}"
puts "   行内容:"
parser.instance_variable_get(:@lines).each_with_index do |line, i|
  puts "     #{i+1}. #{line}"
end
puts ""

puts "2. 逐个检查提取方法..."
puts ""

# 检查运单号提取
puts "   - 运单号提取:"
begin
  tracking_number = parser.send(:extract_tracking_number)
  puts "     ✓ 方法可调用"
  puts "     结果: #{tracking_number || 'nil'}"
  
  # 调试正则表达式
  patterns = [
    /(?:运单号|单号|Tracking|Tracking.*?No)[：:\s]*([A-Z0-9]{10,20})/i,
    /\b(SF|ZT|YT|JD|EMS)[A-Z0-9]{8,18}\b/i,
    /\b([0-9]{12,18})\b/
  ]
  
  patterns.each_with_index do |pattern, i|
    match = TEST_TEXT.match(pattern)
    puts "     模式#{i+1}: #{pattern.inspect} -> #{match ? '匹配: ' + match[1].inspect : '不匹配'}"
  end
  
rescue => e
  puts "     ❌ 方法调用失败: #{e.message}"
end
puts ""

# 检查收件人姓名提取
puts "   - 收件人姓名提取:"
begin
  recipient_name = parser.send(:extract_recipient_name)
  puts "     ✓ 方法可调用"
  puts "     结果: #{recipient_name || 'nil'}"
  
  # 调试提取逻辑
  recipient_keywords = ['收件人', '收货人', '收件', 'To', '收']
  
  recipient_keywords.each do |keyword|
    puts "     关键词 '#{keyword}':"
    parser.instance_variable_get(:@lines).each do |line|
      if line.include?(keyword)
        content = line.split(keyword).last&.strip
        puts "       行 '#{line}' -> 内容: #{content.inspect}"
        if content
          name = content.split(/[：:\s，。、；;]/).first
          puts "       提取姓名: #{name.inspect}"
        end
      end
    end
  end
  
rescue => e
  puts "     ❌ 方法调用失败: #{e.message}"
end
puts ""

# 检查手机号提取
puts "   - 手机号提取:"
begin
  recipient_phone = parser.send(:extract_recipient_phone)
  puts "     ✓ 方法可调用"
  puts "     结果: #{recipient_phone || 'nil'}"
  
  # 调试手机号模式
  phone_pattern = /1[3-9]\d{9}/
  matches = TEST_TEXT.scan(phone_pattern)
  puts "     正则匹配结果: #{matches.inspect}"
  
  # 检查收件人附近的手机号
  recipient_keywords = ['收件人', '收货人', '收件', 'To']
  
  recipient_keywords.each do |keyword|
    puts "     关键词 '#{keyword}':"
    lines = parser.instance_variable_get(:@lines)
    lines.each_cons(2) do |line1, line2|
      if line1.include?(keyword)
        combined = line1 + line2
        match = combined.match(phone_pattern)
        puts "       行1: #{line1}"
        puts "       行2: #{line2}"
        puts "       组合匹配: #{match ? match[0] : '无匹配'}"
      end
    end
  end
  
rescue => e
  puts "     ❌ 方法调用失败: #{e.message}"
end
puts ""

# 检查地址提取
puts "   - 地址提取:"
begin
  recipient_address = parser.send(:extract_recipient_address)
  puts "     ✓ 方法可调用"
  puts "     结果: #{recipient_address || 'nil'}"
  
  # 调试地址提取逻辑
  address_keywords = ['地址', 'Address', '收货地址', '收件地址']
  
  address_keywords.each do |keyword|
    puts "     关键词 '#{keyword}':"
    parser.instance_variable_get(:@lines).each do |line|
      if line.include?(keyword)
        content = line.split(keyword).last&.strip
        puts "       行 '#{line}' -> 内容: #{content.inspect}"
      end
    end
  end
  
  # 检查地址特征
  puts "     地址特征检查:"
  parser.instance_variable_get(:@lines).each do |line|
    looks_like = parser.send(:looks_like_address?, line)
    puts "       行 '#{line}' -> 像地址: #{looks_like}"
  end
  
rescue => e
  puts "     ❌ 方法调用失败: #{e.message}"
end
puts ""

# 检查快递公司提取
puts "   - 快递公司提取:"
begin
  courier_company = parser.send(:extract_courier_company)
  puts "     ✓ 方法可调用"
  puts "     结果: #{courier_company || 'nil'}"
  
  # 调试快递公司匹配
  companies = {
    '顺丰' => '顺丰速运',
    'SF' => '顺丰速运',
    '圆通' => '圆通速递',
    'YT' => '圆通速递',
    '中通' => '中通快递',
    'ZT' => '中通快递',
    '韵达' => '韵达快递',
    'YD' => '韵达快递'
  }
  
  companies.each do |keyword, name|
    if TEST_TEXT.include?(keyword)
      puts "     关键词 '#{keyword}' -> 匹配公司: #{name}"
    end
  end
  
rescue => e
  puts "     ❌ 方法调用失败: #{e.message}"
end
puts ""

# 完整解析测试
puts "3. 完整解析测试:"
begin
  parsed_data = parser.parse
  puts "   ✓ 完整解析成功"
  
  parsed_data.each do |field, value|
    puts "     #{field}: #{value || 'nil'}"
  end
  
rescue => e
  puts "   ❌ 完整解析失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\n      ')}"
end
puts ""

puts "=== 详细调试完成 ==="
puts ""
puts "问题分析:"
puts "1. 检查每个提取方法的实际匹配情况"
puts "2. 分析正则表达式和提取逻辑的问题"
puts "3. 确定需要修复的具体提取规则"