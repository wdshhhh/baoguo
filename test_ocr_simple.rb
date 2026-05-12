#!/usr/bin/env ruby
# 简单OCR测试脚本

require 'rtesseract'
require 'mini_magick'

# 测试文本
test_cases = [
  { text: 'SF1234567890 张三 13800138000 北京市朝阳区', name: '顺丰标准面单' },
  { text: 'YT9876543210 李四 13900139000 上海市浦东新区', name: '圆通标准面单' },
  { text: 'ZT1237894560 王五 13700137000 广州市天河区', name: '中通标准面单' },
  { text: 'JD12345678901 赵六 13600136000 深圳市南山区科技园路', name: '京东标准面单' }
]

puts "📋 OCR识别测试\n\n"

test_cases.each_with_index do |test, index|
  puts "=== 测试 #{index + 1}: #{test[:name]} ==="
  puts "原始文本: #{test[:text]}"
  
  # 创建临时图片
  temp_file = Tempfile.new(['test', '.png'])
  temp_path = temp_file.path
  temp_file.close
  
  # 使用convert命令生成图片
  command = "convert -size 600x80 xc:white -fill black -pointsize 16 -draw \"text 10,40 '#{test[:text]}'\" #{temp_path}"
  system(command)
  
  # 使用Tesseract识别
  begin
    result = RTesseract.new(temp_path, lang: 'chi_sim+eng')
    recognized = result.to_s
    
    puts "识别结果: #{recognized.strip}"
    
    # 简单验证
    success = true
    if recognized.include?(test[:text][0..10])
      puts "✅ 运单号识别成功"
    else
      puts "❌ 运单号识别失败"
      success = false
    end
    
    phone = test[:text].match(/1[3-9]\d{9}/)
    if phone && recognized.include?(phone[0])
      puts "✅ 手机号识别成功"
    else
      puts "❌ 手机号识别失败"
      success = false
    end
    
    puts "整体结果: #{success ? '✅ 通过' : '❌ 部分失败'}\n\n"
    
  rescue => e
    puts "❌ 识别异常: #{e.message}\n\n"
  ensure
    File.delete(temp_path) if File.exist?(temp_path)
  end
end

puts "🎉 测试完成！"
