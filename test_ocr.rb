#!/usr/bin/env ruby

# OCR功能测试脚本
require 'mini_magick'
require 'rtesseract'

puts "=== OCR功能测试 ==="
puts ""

# 测试图片处理
def test_image_processing
  puts "1. 测试图片处理..."
  begin
    # 检查是否有可用的图片文件
    logo_path = 'app/assets/images/logo.png'
    
    if File.exist?(logo_path)
      image = MiniMagick::Image.open(logo_path)
      
      # 调整大小
      image.resize '800x600'
      
      # 增强对比度
      image.contrast(20)
      
      puts "   ✓ 图片处理测试通过"
      return true
    else
      # 如果没有logo文件，创建一个简单的测试图片
      test_image_path = '/tmp/ocr_simple_test.jpg'
      
      # 使用系统命令创建测试图片
      system('convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 "测试文字" /tmp/ocr_simple_test.jpg 2>/dev/null')
      
      if File.exist?(test_image_path)
        image = MiniMagick::Image.open(test_image_path)
        
        # 调整大小
        image.resize '800x600'
        
        # 增强对比度
        image.contrast(20)
        
        puts "   ✓ 图片处理测试通过"
        return true
      else
        puts "   ⚠ 无法创建测试图片，跳过图片处理测试"
        return false
      end
    end
  rescue => e
    puts "   ✗ 图片处理测试失败: #{e.message}"
    return false
  end
end

# 测试OCR识别
def test_ocr_recognition
  puts "2. 测试OCR识别..."
  begin
    # 创建一个简单的文本图片
    test_image_path = '/tmp/ocr_text_test.png'
    
    # 使用系统命令创建测试图片
    system('convert -size 400x200 xc:white -pointsize 24 -fill black -gravity center -annotate +0+0 "测试文字 123456" /tmp/ocr_text_test.png 2>/dev/null')
    
    if File.exist?(test_image_path)
      # 尝试识别
      text = RTesseract.new(test_image_path, lang: 'chi_sim+eng').to_s.strip
      
      if text.present?
        puts "   ✓ OCR识别测试通过"
        puts "   识别结果: #{text}"
        
        # 检查识别质量
        if text.include?('测试') || text.include?('123')
          puts "   ✓ 识别质量良好"
        else
          puts "   ⚠ 识别结果可能不准确"
        end
        
        return true
      else
        puts "   ✗ OCR识别结果为空"
        return false
      end
    else
      puts "   ✗ 测试图片创建失败"
      return false
    end
  rescue => e
    puts "   ✗ OCR识别测试失败: #{e.message}"
    return false
  ensure
    # 清理测试文件
    File.delete(test_image_path) if test_image_path && File.exist?(test_image_path)
  end
end

# 测试Tesseract配置
def test_tesseract_config
  puts "3. 测试Tesseract配置..."
  begin
    # 检查Tesseract版本
    version = `tesseract --version 2>&1`
    if version.include?('tesseract')
      puts "   ✓ Tesseract版本: #{version.lines.first.strip}"
    else
      puts "   ✗ Tesseract版本检查失败"
      return false
    end
    
    # 检查语言包
    langs = `tesseract --list-langs 2>&1`
    if langs.include?('chi_sim')
      puts "   ✓ 中文语言包已安装"
    else
      puts "   ✗ 中文语言包未安装"
      return false
    end
    
    # 检查RTesseract
    begin
      RTesseract.new('/tmp/test.png', lang: 'chi_sim+eng')
      puts "   ✓ RTesseract配置正常"
      return true
    rescue => e
      puts "   ✗ RTesseract配置失败: #{e.message}"
      return false
    end
    
  rescue => e
    puts "   ✗ Tesseract配置测试失败: #{e.message}"
    return false
  end
end

# 运行测试
puts "开始OCR功能测试..."
puts ""

image_processing_ok = test_image_processing
ocr_recognition_ok = test_ocr_recognition
tesseract_config_ok = test_tesseract_config

puts ""
puts "=== 测试结果 ==="
puts "图片处理: #{image_processing_ok ? '✓ 通过' : '✗ 失败'}"
puts "OCR识别: #{ocr_recognition_ok ? '✓ 通过' : '✗ 失败'}"
puts "Tesseract配置: #{tesseract_config_ok ? '✓ 通过' : '✗ 失败'}"
puts ""

if image_processing_ok && ocr_recognition_ok && tesseract_config_ok
  puts "🎉 OCR系统基本功能正常"
  puts ""
  puts "下一步操作:"
  puts "1. 重启Rails服务器: pkill -f 'rails server' && rails server"
  puts "2. 访问 http://localhost:3000/pc/packages"
  puts "3. 测试OCR功能上传快递面单图片"
else
  puts "⚠ OCR系统存在一些问题"
  puts ""
  puts "建议检查:"
  puts "• ImageMagick是否正确安装"
  puts "• Tesseract中文语言包是否安装"
  puts "• 系统权限是否足够"
  puts "• 查看Rails日志获取详细错误信息"
end