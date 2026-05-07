#!/usr/bin/env ruby

# OCR识别质量优化测试
require_relative 'config/environment'

puts "=== OCR识别质量优化测试 ==="
puts ""

# 测试不同图片预处理方法
puts "1. 图片预处理方法测试:"
puts ""

# 创建不同质量的测试图片
test_images = {}

# 方法1：简单文本图片
puts "   - 方法1: 简单文本图片"
simple_image_path = "/tmp/simple_test_#{Time.now.to_i}.jpg"
system("convert -size 400x300 xc:white -pointsize 18 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{simple_image_path}")
test_images[:simple] = simple_image_path

# 方法2：增强对比度图片
puts "   - 方法2: 增强对比度图片"
contrast_image_path = "/tmp/contrast_test_#{Time.now.to_i}.jpg"
system("convert -size 400x300 xc:white -pointsize 18 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' -contrast-stretch 0x10% #{contrast_image_path}")
test_images[:contrast] = contrast_image_path

# 方法3：灰度化图片
puts "   - 方法3: 灰度化图片"
gray_image_path = "/tmp/gray_test_#{Time.now.to_i}.jpg"
system("convert -size 400x300 xc:white -pointsize 18 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' -colorspace Gray #{gray_image_path}")
test_images[:gray] = gray_image_path

# 方法4：高分辨率图片
puts "   - 方法4: 高分辨率图片"
hd_image_path = "/tmp/hd_test_#{Time.now.to_i}.jpg"
system("convert -size 800x600 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{hd_image_path}")
test_images[:hd] = hd_image_path

puts ""

# 测试每种图片的OCR识别效果
test_images.each do |method, image_path|
  if File.exist?(image_path)
    puts "   #{method.to_s.capitalize}图片测试:"
    
    # 使用FixedOcrService测试
    fixed_service = FixedOcrService.new(image_path)
    result = fixed_service.recognize
    
    if result[:success]
      puts "     ✅ OCR识别成功"
      puts "       置信度: #{result[:confidence]}"
      puts "       识别文本: #{result[:raw_text][0..100]}..."
      
      # 使用OcrResultParser解析
      parser = OcrResultParser.new(result[:raw_text])
      parsed_data = parser.parse
      
      # 计算有效字段数量
      valid_fields = parsed_data.select { |k, v| v && !v.to_s.empty? }.size
      total_fields = parsed_data.size
      accuracy = (valid_fields.to_f / total_fields * 100).round(2)
      
      puts "       解析准确率: #{accuracy}%"
      
    else
      puts "     ❌ OCR识别失败: #{result[:error]}"
    end
    
    puts ""
    
    # 清理测试文件
    File.delete(image_path)
  else
    puts "   ❌ #{method}图片创建失败"
  end
end

puts ""

# 测试2：优化Tesseract参数
puts "2. Tesseract参数优化测试:"
puts ""

# 创建测试图片
optimize_image_path = "/tmp/optimize_test_#{Time.now.to_i}.jpg"
system("convert -size 600x400 xc:white -pointsize 20 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{optimize_image_path}")

if File.exist?(optimize_image_path)
  puts "   ✅ 优化测试图片创建成功"
  
  # 测试不同Tesseract参数
  test_params = [
    { psm: 6, oem: 3, lang: 'chi_sim+eng' },
    { psm: 8, oem: 3, lang: 'chi_sim+eng' },
    { psm: 3, oem: 3, lang: 'chi_sim+eng' },
    { psm: 6, oem: 1, lang: 'chi_sim+eng' },
    { psm: 6, oem: 3, lang: 'eng+chi_sim' }
  ]
  
  test_params.each_with_index do |params, i|
    puts "   - 参数组合#{i+1}: PSM=#{params[:psm]}, OEM=#{params[:oem]}, LANG=#{params[:lang]}"
    
    begin
      # 直接调用Tesseract
      tesseract_cmd = "tesseract #{optimize_image_path} stdout --psm #{params[:psm]} --oem #{params[:oem]} -l #{params[:lang]} 2>/dev/null"
      result = `#{tesseract_cmd}`.strip
      
      if result && !result.empty?
        puts "     ✅ 识别成功"
        puts "       识别文本: #{result[0..80]}..."
        
        # 检查中文识别效果
        chinese_chars = result.scan(/[\u4e00-\u9fa5]/).size
        puts "       中文字符数: #{chinese_chars}"
        
      else
        puts "     ❌ 识别失败"
      end
      
    rescue => e
      puts "     ❌ 调用失败: #{e.message}"
    end
    
    puts ""
  end
  
  # 清理测试文件
  File.delete(optimize_image_path)
  
else
  puts "   ❌ 优化测试图片创建失败"
end

puts ""

# 测试3：检查中文语言包支持
puts "3. 中文语言包支持检查:"
puts ""

begin
  # 检查Tesseract语言包
  lang_check = `tesseract --list-langs 2>&1`
  
  if lang_check.include?("chi_sim")
    puts "   ✅ 简体中文语言包已安装"
  else
    puts "   ❌ 简体中文语言包未安装"
  end
  
  if lang_check.include?("chi_tra")
    puts "   ✅ 繁体中文语言包已安装"
  else
    puts "   ❌ 繁体中文语言包未安装"
  end
  
  # 测试中文识别
  puts ""
  puts "   - 中文识别测试:"
  
  chinese_test_path = "/tmp/chinese_test_#{Time.now.to_i}.jpg"
  system("convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 '顺丰快递 张三 北京市朝阳区' #{chinese_test_path}")
  
  if File.exist?(chinese_test_path)
    # 使用中文语言包识别
    tesseract_cmd = "tesseract #{chinese_test_path} stdout -l chi_sim 2>/dev/null"
    result = `#{tesseract_cmd}`.strip
    
    if result && !result.empty?
      puts "     ✅ 中文识别成功"
      puts "       识别结果: #{result}"
    else
      puts "     ❌ 中文识别失败"
    end
    
    File.delete(chinese_test_path)
  end
  
rescue => e
  puts "   ❌ 语言包检查失败: #{e.message}"
end

puts ""
puts "=== OCR质量优化测试完成 ==="
puts ""
puts "优化建议:"
puts "1. 优化图片预处理参数（对比度、分辨率）"
puts "2. 调整Tesseract识别参数（PSM、OEM模式）"
puts "3. 确保中文语言包正确安装"
puts "4. 考虑使用更高质量的测试图片"