#!/usr/bin/env ruby

# 测试PaddleOCR中文识别能力
require_relative 'config/environment'

puts "=== 测试PaddleOCR中文识别能力 ==="
puts ""

# 创建一个包含中文的真实面单测试图片
require 'mini_magick'

puts "1. 创建中文面单测试图片..."

# 创建一个白色背景图片
image = MiniMagick::Tool::Convert.new do |convert|
  convert.size '600x400'
  convert.xc 'white'
  convert << '/tmp/real_chinese_parcel.jpg'
end

puts "   基础图片创建成功"

# 添加中文文本
image = MiniMagick::Image.open('/tmp/real_chinese_parcel.jpg')

# 添加中文文本（模拟真实面单）
image.combine_options do |c|
  c.font 'Arial'
  c.pointsize 16
  c.fill 'black'
  c.gravity 'northwest'
  c.annotate '+20+20', '顺丰速运'
  c.annotate '+20+50', '运单号: SF1234567890'
  c.annotate '+20+80', '收件人: 张三'
  c.annotate '+20+110', '电话: 13800138000'
  c.annotate '+20+140', '地址: 北京市朝阳区某某街道123号'
end

image.write('/tmp/real_chinese_parcel.jpg')
puts "   中文面单测试图片创建成功: /tmp/real_chinese_parcel.jpg"
puts ""

# 测试PaddleOCR识别中文
puts "2. 测试PaddleOCR中文识别..."

begin
  service = PaddleOcrService.new('/tmp/real_chinese_parcel.jpg')
  result = service.recognize
  
  puts "   PaddleOCR识别结果:"
  puts "   成功: #{result[:success]}"
  puts "   识别文本: #{result[:raw_text].inspect}"
  puts "   置信度: #{result[:confidence]}"
  puts "   处理时间: #{result[:processing_time]}秒"
  puts "   中文字符数: #{result[:chinese_count]}"
  puts ""
  
  # 解析识别结果
  if result[:success] && result[:raw_text] && !result[:raw_text].empty?
    puts "3. 解析结果:"
    
    # 检查是否包含中文
    chinese_chars = result[:raw_text].scan(/[\u4e00-\u9fff]/)
    puts "   识别到的中文字符: #{chinese_chars.join(' ')}"
    puts "   中文字符总数: #{chinese_chars.size}"
    
    # 检查关键信息
    if result[:raw_text].include?('顺丰')
      puts "   ✅ 成功识别快递公司: 顺丰"
    else
      puts "   ❌ 未识别到快递公司"
    end
    
    if result[:raw_text].include?('张三')
      puts "   ✅ 成功识别收件人: 张三"
    else
      puts "   ❌ 未识别到收件人"
    end
    
    if result[:raw_text].include?('13800138000')
      puts "   ✅ 成功识别电话"
    else
      puts "   ❌ 未识别到电话"
    end
    
    if result[:raw_text].include?('北京')
      puts "   ✅ 成功识别地址"
    else
      puts "   ❌ 未识别到地址"
    end
    
  else
    puts "   ❌ 识别失败或文本为空"
  end
  
rescue => e
  puts "   PaddleOCR识别错误: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""
puts "=== 测试完成 ==="