#!/usr/bin/env ruby

# OCR诊断和优化脚本
require 'fileutils'
require 'mini_magick'

puts "=== OCR系统诊断工具 ==="
puts ""

# 1. 检查系统环境
puts "1. 检查系统环境:"
puts "   操作系统: #{`uname -a`.strip}"
puts "   Ruby版本: #{`ruby --version`.strip}"
puts "   Rails版本: #{`rails --version`.strip rescue 'N/A'}"
puts ""

# 2. 检查Tesseract安装
puts "2. 检查Tesseract安装:"
puts "   Tesseract路径: #{`which tesseract`.strip}"
puts "   Tesseract版本: #{`tesseract --version`.strip}"
puts "   可用语言包: #{`tesseract --list-langs`.strip}"
puts ""

# 3. 检查Ruby依赖
puts "3. 检查Ruby依赖:"
begin
  require 'rtesseract'
  puts "   ✓ RTesseract已加载"
rescue => e
  puts "   ✗ RTesseract加载失败: #{e.message}"
end

begin
  require 'mini_magick'
  puts "   ✓ MiniMagick已加载"
rescue => e
  puts "   ✗ MiniMagick加载失败: #{e.message}"
end
puts ""

# 4. 测试Tesseract功能
puts "4. 测试Tesseract功能:"
begin
  # 创建测试图片
  test_image_path = '/tmp/ocr_test.png'

  # 使用MiniMagick创建测试图片
  image = MiniMagick::Image.new(test_image_path)
  image.combine_options do |c|
    c.size "300x150"
    c.gravity "center"
    c.xc "white"
    c.pointsize "24"
    c.annotate "+0+0", "顺丰快递 SF1234567890"
    c.fill "black"
  end
  image.write(test_image_path)

  puts "   ✓ 测试图片创建成功: #{test_image_path}"

  # 测试识别
  test_text = RTesseract.new(test_image_path, lang: 'chi_sim+eng').to_s.strip
  puts "   ✓ 识别测试结果: #{test_text}"

  # 清理测试文件
  File.delete(test_image_path) if File.exist?(test_image_path)

rescue => e
  puts "   ✗ 功能测试失败: #{e.message}"
end
puts ""

# 5. 检查项目配置
puts "5. 检查项目配置:"
config_file = File.expand_path('../config/ocr_config.yml', __dir__)
if File.exist?(config_file)
  puts "   ✓ OCR配置文件存在: #{config_file}"
  puts "   配置文件内容:"
  puts File.read(config_file)
else
  puts "   ✗ OCR配置文件不存在"
end
puts ""

# 6. 检查OCR服务类
puts "6. 检查OCR服务类:"
service_files = [
  'app/services/tesseract_ocr_service.rb',
  'app/services/optimized_ocr_service.rb',
  'app/services/image_processing_service.rb',
  'app/services/ocr_result_parser.rb'
]

service_files.each do |file|
  full_path = File.expand_path("../#{file}", __dir__)
  if File.exist?(full_path)
    puts "   ✓ #{file} 存在"
  else
    puts "   ✗ #{file} 不存在"
  end
end
puts ""

# 7. 优化建议
puts "7. 优化建议:"
puts "   • 确保Tesseract中文语言包已安装: sudo apt install tesseract-ocr-chi-sim"
puts "   • 检查图片质量: 使用清晰、高对比度的图片"
puts "   • 调整图片大小: 建议800-1200像素宽度"
puts "   • 使用正面拍摄: 避免角度变形和反光"
puts "   • 测试不同PSM模式: 6(统一文本块), 8(单词), 3(行)"
puts ""

puts "=== 诊断完成 ==="

# 8. 创建优化配置文件
puts "8. 创建优化配置文件..."
begin
  require 'yaml'

  optimized_config = {
    'tesseract' => {
      'lang' => 'chi_sim+eng',
      'psm_modes' => [ 6, 8, 3 ],
      'oem' => 3
    },
    'image_processing' => {
      'max_width' => 1200,
      'max_height' => 1200,
      'min_width' => 800,
      'min_height' => 800,
      'contrast' => 30,
      'brightness' => 15,
      'sharpen' => '0x0.8'
    },
    'patterns' => {
      'tracking_number' => [
        '(?:运单号|单号|快递单号|Tracking)[：:\s]*([A-Z0-9]{10,20})',
        '\\b(SF|ZT|YT|JD|EMS|STO|ZTO|YTO|HTKY)[A-Z0-9]{8,18}\\b',
        '\\b([0-9]{12,18})\\b'
      ],
      'phone' => [
        '1[3-9]\\d{9}',
        '(?:手机|电话|联系方式)[：:\s]*(1[3-9]\\d{9})'
      ]
    }
  }

  config_path = File.expand_path('../config/optimized_ocr_config.yml', __dir__)
  File.write(config_path, YAML.dump(optimized_config))
  puts "   ✓ 优化配置文件已创建: #{config_path}"
rescue => e
  puts "   ⚠ 配置文件创建失败: #{e.message}"
end
puts ""

puts "=== 优化完成 ==="
puts "请重启Rails服务器以应用优化配置:"
puts "rails server"
puts ""
puts "然后测试OCR功能:"
puts "1. 访问 http://localhost:3000/pc/packages"
puts "2. 点击'新增包裹'"
puts "3. 使用'OCR识别面单'功能上传图片"
puts "4. 查看识别结果和日志输出"
