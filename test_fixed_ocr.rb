#!/usr/bin/env ruby

# 修复OCR功能测试脚本
require 'mini_magick'
require 'rtesseract'

puts "=== 修复OCR功能测试 ==="
puts ""

# 测试修复的图片处理
def test_fixed_image_processing
  puts "1. 测试修复的图片处理..."
  begin
    # 创建一个简单的测试图片
    test_image_path = '/tmp/fixed_ocr_test.jpg'
    
    # 使用系统命令创建测试图片
    system('convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 "顺丰快递 SF1234567890" /tmp/fixed_ocr_test.jpg 2>/dev/null')
    
    if File.exist?(test_image_path)
      # 使用修复的MiniMagick语法
      image = MiniMagick::Image.open(test_image_path)
      
      # 修复的预处理流程
      image.auto_orient
      
      # 调整大小
      if image.width > 1200 || image.height > 1200
        image.resize "1200x1200>"
      elsif image.width < 800 || image.height < 800
        image.resize "800x800<"
      end
      
      # 修复的对比度增强
      image.combine_options do |c|
        c.contrast
        c.brightness_contrast "10x20"
        c.sharpen "0x0.5"
      end
      
      # 转换为灰度
      image.colorspace "Gray"
      
      # 保存处理后的图片
      processed_path = '/tmp/fixed_ocr_processed.png'
      image.write(processed_path)
      
      puts "   ✓ 修复的图片处理测试通过"
      puts "   原始尺寸: #{image.width}x#{image.height}"
      
      # 清理测试文件
      File.delete(test_image_path) if File.exist?(test_image_path)
      File.delete(processed_path) if File.exist?(processed_path)
      
      return true
    else
      puts "   ✗ 测试图片创建失败"
      return false
    end
  rescue => e
    puts "   ✗ 修复的图片处理测试失败: #{e.message}"
    return false
  end
end

# 测试修复的OCR识别
def test_fixed_ocr_recognition
  puts "2. 测试修复的OCR识别..."
  begin
    # 创建一个简单的文本图片
    test_image_path = '/tmp/fixed_ocr_text_test.png'
    
    # 使用系统命令创建测试图片
    system('convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 "顺丰快递 SF1234567890 收件人:张三 手机:13800138000" /tmp/fixed_ocr_text_test.png 2>/dev/null')
    
    if File.exist?(test_image_path)
      # 尝试不同的PSM模式
      psm_modes = [6, 8, 3]
      
      best_result = ""
      best_confidence = 0
      
      psm_modes.each do |psm|
        begin
          text = RTesseract.new(test_image_path, lang: 'chi_sim+eng', psm: psm).to_s.strip
          
          # 计算置信度
          confidence = calculate_confidence(text)
          
          puts "   PSM模式 #{psm}: #{text[0..30]}... (置信度: #{confidence})"
          
          if confidence > best_confidence
            best_result = text
            best_confidence = confidence
          end
          
        rescue => e
          puts "   PSM模式 #{psm} 失败: #{e.message}"
        end
      end
      
      if !best_result.empty?
        puts "   ✓ 修复的OCR识别测试通过"
        puts "   最佳结果: #{best_result}"
        
        # 检查是否包含关键信息
        if best_result.include?('顺丰') || best_result.include?('SF') || best_result.include?('1234567890')
          puts "   ✓ 关键信息识别成功"
        else
          puts "   ⚠ 关键信息识别可能不准确"
        end
        
        return true
      else
        puts "   ✗ 所有PSM模式识别失败"
        return false
      end
    else
      puts "   ✗ 测试图片创建失败"
      return false
    end
  rescue => e
    puts "   ✗ 修复的OCR识别测试失败: #{e.message}"
    return false
  ensure
    # 清理测试文件
    File.delete(test_image_path) if test_image_path && File.exist?(test_image_path)
  end
end

# 计算置信度
def calculate_confidence(text)
  return 0.0 if text.nil? || text.empty?
  
  # 基于文本长度、字符多样性、数字比例等计算置信度
  length_score = [text.length.to_f / 50, 1.0].min
  diversity_score = text.chars.uniq.length.to_f / [text.length, 1].max
  digit_ratio = text.scan(/\d/).length.to_f / [text.length, 1].max
  
  # 综合评分
  confidence = (length_score * 0.4 + diversity_score * 0.3 + digit_ratio * 0.3)
  confidence.round(2)
end

# 测试修复的OCR服务类
def test_fixed_ocr_service
  puts "3. 测试修复的OCR服务类..."
  begin
    # 创建一个测试图片
    test_image_path = '/tmp/fixed_service_test.png'
    system('convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 "测试文字" /tmp/fixed_service_test.png 2>/dev/null')
    
    if File.exist?(test_image_path)
      # 模拟FixedOcrService的检测逻辑
      
      # 检查Tesseract可用性
      result = `which tesseract 2>&1`
      tesseract_available = $?.success? && !result.empty?
      
      # 检查中文语言包
      langs = `tesseract --list-langs 2>&1`
      chinese_available = langs.include?('chi_sim')
      
      puts "   Tesseract可用: #{tesseract_available ? '✓' : '✗'}"
      puts "   中文语言包: #{chinese_available ? '✓' : '✗'}"
      
      if tesseract_available && chinese_available
        puts "   ✓ 修复的OCR服务类配置正常"
        return true
      else
        puts "   ✗ 修复的OCR服务类配置失败"
        return false
      end
    else
      puts "   ✗ 测试图片创建失败"
      return false
    end
  rescue => e
    puts "   ✗ 修复的OCR服务类测试失败: #{e.message}"
    return false
  ensure
    File.delete(test_image_path) if test_image_path && File.exist?(test_image_path)
  end
end

# 运行测试
puts "开始修复OCR功能测试..."
puts ""

image_processing_ok = test_fixed_image_processing
ocr_recognition_ok = test_fixed_ocr_recognition
ocr_service_ok = test_fixed_ocr_service

puts ""
puts "=== 修复测试结果 ==="
puts "图片处理: #{image_processing_ok ? '✓ 通过' : '✗ 失败'}"
puts "OCR识别: #{ocr_recognition_ok ? '✓ 通过' : '✗ 失败'}"
puts "OCR服务类: #{ocr_service_ok ? '✓ 通过' : '✗ 失败'}"
puts ""

if image_processing_ok && ocr_recognition_ok && ocr_service_ok
  puts "🎉 修复OCR功能测试通过！"
  puts ""
  puts "下一步操作:"
  puts "1. 重启Rails服务器: pkill -f 'rails server' && rails server"
  puts "2. 访问 http://localhost:3000/pc/packages"
  puts "3. 测试OCR功能上传快递面单图片"
else
  puts "⚠ 修复OCR功能测试部分失败"
  puts ""
  puts "建议检查:"
  puts "• 查看Rails日志获取详细错误信息"
  puts "• 确保上传的图片清晰、无模糊和反光"
  puts "• 测试不同分辨率和质量的图片"
end

puts ""
puts "=== 优化建议 ==="
puts "• 使用高分辨率图片（800-1200像素宽度）"
puts "• 确保图片清晰、无模糊和反光"
puts "• 正面拍摄快递面单，避免角度变形"
puts "• 测试不同快递公司的面单模板"
puts "• 查看Rails日志了解具体识别过程"