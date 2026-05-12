#!/usr/bin/env ruby
# 完整OCR识别测试

require 'rtesseract'
require 'mini_magick'

# 创建测试面单数据
test_parcels = [
  {
    company: '顺丰速运',
    tracking_number: 'SF123456789012',
    name: '张三',
    phone: '13800138000',
    address: '北京市朝阳区科技园路128号阳光花园5栋1001室'
  },
  {
    company: '圆通速递',
    tracking_number: 'YT987654321012',
    name: '李四',
    phone: '13900139000',
    address: '上海市浦东新区张江高科技园区88号'
  },
  {
    company: '中通快递',
    tracking_number: 'ZT123456789012',
    name: '王五',
    phone: '13700137000',
    address: '广州市天河区珠江新城CBD中心大厦15楼'
  },
  {
    company: '京东物流',
    tracking_number: 'JD1234567890123',
    name: '赵六',
    phone: '13600136000',
    address: '深圳市南山区科技园南区深南大道9999号'
  }
]

def generate_parcel_image(data, output_path)
  commands = [
    "-fill '#DC2626' -pointsize 24 -draw \"text 20,50 '#{data[:company]}'\"",
    "-fill '#1f2937' -pointsize 18 -draw \"text 20,90 '运单号: #{data[:tracking_number]}'\"",
    "-fill '#6b7280' -pointsize 14 -draw \"text 20,120 '收件人信息'\"",
    "-fill '#1f2937' -pointsize 16 -draw \"text 20,150 '姓名: #{data[:name]}'\"",
    "-fill '#1f2937' -pointsize 16 -draw \"text 20,180 '电话: #{data[:phone]}'\"",
    "-fill '#1f2937' -pointsize 14 -draw \"text 20,210 '地址: #{data[:address][0..25]}'\"",
    "-fill '#1f2937' -pointsize 14 -draw \"text 20,235 '#{data[:address][25..50]}'\""
  ]
  
  command = "convert -size 500x300 xc:white #{commands.join(' ')} #{output_path}"
  system(command)
end

def extract_tracking_number(text)
  patterns = [
    /([A-Z]{2}[0-9]{8,16})/,
    /([A-Z]{3}[0-9]{8,14})/,
    /([0-9]{10,18})/
  ]
  patterns.each do |pattern|
    match = text.match(pattern)
    return match[1] if match
  end
  nil
end

def extract_phone(text)
  match = text.gsub(/\s/, '').match(/(1[3-9][0-9]{9})/)
  match ? match[1] : nil
end

def extract_name(text)
  match = text.match(/姓名[：:]\s*([\u4e00-\u9fa5]{2,4})/)
  return match[1] if match
  
  matches = text.scan(/([\u4e00-\u9fa5]{2,4})/)
  matches.flatten.each do |name|
    return name unless ['顺丰', '圆通', '中通', '韵达', '申通', '京东', '电话', '地址', '姓名'].include?(name)
  end
  nil
end

def extract_address(text)
  lines = text.split("\n")
  address_lines = []
  
  lines.each do |line|
    if line.include?('地址') || line.include?('市') || line.include?('区') || line.include?('路') || line.include?('号') || line.include?('栋') || line.include?('室')
      address_lines << line.gsub(/地址[：:]\s*/, '').strip
    end
  end
  
  address_lines.join(' ') if address_lines.any?
end

def extract_company(text)
  companies = {
    '顺丰' => '顺丰速运',
    '圆通' => '圆通速递',
    '中通' => '中通快递',
    '韵达' => '韵达快递',
    '申通' => '申通快递',
    '京东' => '京东物流',
    'EMS' => 'EMS'
  }
  
  companies.each do |keyword, company|
    return company if text.include?(keyword)
  end
  nil
end

# 生成并测试
puts "🚀 开始OCR测试..."
puts "=" * 60

test_parcels.each_with_index do |parcel, index|
  puts "\n📦 测试面单 #{index + 1}: #{parcel[:company]}"
  puts "─" * 40
  
  # 生成测试图片
  temp_file = Tempfile.new(['parcel', '.png'])
  temp_path = temp_file.path
  temp_file.close
  generate_parcel_image(parcel, temp_path)
  
  # OCR识别
  begin
    puts "正在识别..."
    result = RTesseract.new(temp_path, lang: 'chi_sim+eng')
    raw_text = result.to_s
    
    puts "\n📝 原始识别文本:"
    puts raw_text
    
    # 提取字段
    extracted = {
      tracking_number: extract_tracking_number(raw_text),
      name: extract_name(raw_text),
      phone: extract_phone(raw_text),
      company: extract_company(raw_text),
      address: extract_address(raw_text)
    }
    
    puts "\n🎯 提取结果:"
    puts "运单号: #{extracted[:tracking_number] || '未识别'}"
    puts "姓名: #{extracted[:name] || '未识别'}"
    puts "电话: #{extracted[:phone] || '未识别'}"
    puts "快递公司: #{extracted[:company] || '未识别'}"
    puts "地址: #{extracted[:address] || '未识别'}"
    
    # 验证
    puts "\n✅ 验证结果:"
    correct = 0
    total = 5
    
    correct += 1 if extracted[:tracking_number] == parcel[:tracking_number]
    puts "运单号: #{extracted[:tracking_number] == parcel[:tracking_number] ? '✓' : '✗'}"
    
    correct += 1 if extracted[:name] == parcel[:name]
    puts "姓名: #{extracted[:name] == parcel[:name] ? '✓' : '✗'}"
    
    correct += 1 if extracted[:phone] == parcel[:phone]
    puts "电话: #{extracted[:phone] == parcel[:phone] ? '✓' : '✗'}"
    
    correct += 1 if extracted[:company] == parcel[:company]
    puts "快递公司: #{extracted[:company] == parcel[:company] ? '✓' : '✗'}"
    
    address_ok = extracted[:address] && parcel[:address].include?(extracted[:address][0..10])
    correct += 1 if address_ok
    puts "地址: #{address_ok ? '✓' : '✗'}"
    
    puts "\n📊 识别准确率: #{correct}/#{total} (#{(correct.to_f/total*100).round}%)"
    
  rescue => e
    puts "❌ 识别失败: #{e.message}"
  ensure
    File.delete(temp_path) if File.exist?(temp_path)
  end
end

puts "\n" + "=" * 60
puts "🎉 测试完成！"
