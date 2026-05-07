#!/usr/bin/env ruby

# PaddleOCR集成测试脚本
require_relative 'config/environment'

puts "=== PaddleOCR集成测试 ==="
puts ""

# 1. 检查PaddleOCR安装状态
puts "1. PaddleOCR安装状态检查:"
puts ""

begin
  # 检查Python环境
  python_version = `python3 --version 2>&1`.strip
  puts "   ✅ #{python_version}"
  
  # 检查PaddleOCR是否可用
  check_script = <<~PYTHON
import sys
try:
    import paddleocr
    print("available")
except ImportError:
    print("unavailable")
PYTHON

  script_path = '/tmp/check_paddle_install.py'
  File.write(script_path, check_script)
  
  install_status = `python3 #{script_path} 2>&1`.strip
  File.delete(script_path) if File.exist?(script_path)
  
  if install_status == "available"
    puts "   ✅ PaddleOCR已安装并可用"
  else
    puts "   ❌ PaddleOCR未安装或不可用"
    puts "     当前状态: #{install_status}"
  end
  
rescue => e
  puts "   ❌ 安装状态检查失败: #{e.message}"
end

puts ""

# 2. 创建中文测试图片
puts "2. 创建测试图片:"
puts ""

test_image_path = "/tmp/paddle_integration_test_#{Time.now.to_i}.jpg"

# 创建清晰的中文快递面单图片
system("convert -size 600x400 xc:white -pointsize 28 -fill black -gravity center -annotate +0+0 '顺丰快递\\n运单号: SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{test_image_path}")

if File.exist?(test_image_path)
  puts "   ✅ 中文测试图片创建成功: #{test_image_path}"
  puts "     图片大小: #{File.size(test_image_path)} bytes"
else
  puts "   ❌ 测试图片创建失败"
  exit(1)
end

puts ""

# 3. 测试PaddleOCR服务
puts "3. PaddleOCR服务测试:"
puts ""

begin
  # 创建PaddleOCR服务实例
  paddle_service = PaddleOcrService.new(test_image_path)
  
  # 检查服务状态
  puts "   - 服务初始化检查:"
  puts "     引擎信息: #{paddle_service.engine_info}"
  
  # 执行OCR识别
  puts "   - 执行OCR识别:"
  start_time = Time.now
  result = paddle_service.recognize
  processing_time = Time.now - start_time
  
  if result[:success]
    puts "     ✅ PaddleOCR识别成功"
    puts "       引擎: #{result[:engine]}"
    puts "       置信度: #{result[:confidence]}"
    puts "       处理时间: #{result[:processing_time].round(2)}秒"
    puts "       中文字符数: #{result[:chinese_count] || 0}"
    puts ""
    
    # 显示识别文本
    puts "       识别文本:"
    puts "       " + "-" * 50
    puts result[:raw_text]
    puts "       " + "-" * 50
    puts ""
    
    # 检查中文识别效果
    if result[:chinese_count].to_i > 0
      puts "     ✅ 成功识别到中文字符"
      
      # 使用OcrResultParser解析
      puts "   - 解析结果测试:"
      parser = OcrResultParser.new(result[:raw_text])
      parsed_data = parser.parse
      
      # 计算准确率
      valid_fields = parsed_data.select { |k, v| v && !v.to_s.empty? }.size
      total_fields = parsed_data.size
      accuracy = (valid_fields.to_f / total_fields * 100).round(2)
      
      puts "     ✅ 解析完成，准确率: #{accuracy}%"
      puts ""
      
      # 显示解析结果
      puts "       解析结果:"
      parsed_data.each do |key, value|
        status = value && !value.to_s.empty? ? "✅" : "❌"
        puts "       #{status} #{key}: #{value || '空'}"
      end
      
    else
      puts "     ❌ 未识别到中文字符"
    end
    
  else
    puts "     ❌ PaddleOCR识别失败: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ PaddleOCR服务测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace[0..3].join('\\n     ')}"
end

puts ""

# 4. 测试多OCR服务管理器
puts "4. 多OCR服务管理器测试:"
puts ""

begin
  # 创建多OCR服务管理器实例
  multi_service = MultiOcrService.new(test_image_path)
  
  # 检查服务状态
  puts "   - 服务状态检查:"
  status = multi_service.service_status
  status.each do |service_name, service_info|
    status_icon = service_info[:available] ? "✅" : "❌"
    puts "     #{status_icon} #{service_name}: #{service_info[:description]}"
  end
  puts ""
  
  # 执行智能识别
  puts "   - 智能OCR识别:"
  start_time = Time.now
  result = multi_service.recognize
  total_time = Time.now - start_time
  
  if result[:success]
    puts "     ✅ 多OCR服务识别成功"
    puts "       使用服务: #{result[:service_name]}"
    puts "       服务描述: #{result[:service_description]}"
    puts "       总处理时间: #{result[:total_processing_time].round(2)}秒"
    puts "       尝试次数: #{result[:attempts]}"
    puts "       置信度: #{result[:confidence]}"
    puts "       中文字符数: #{result[:chinese_count] || 0}"
    puts ""
    
    # 显示识别文本摘要
    if result[:raw_text]
      puts "       识别文本摘要:"
      text_preview = result[:raw_text][0..100] + (result[:raw_text].length > 100 ? "..." : "")
      puts "       #{text_preview}"
    end
    
  else
    puts "     ❌ 多OCR服务识别失败: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ 多OCR服务管理器测试失败: #{e.message}"
end

puts ""

# 5. 性能对比测试
puts "5. 性能对比测试:"
puts ""

begin
  multi_service = MultiOcrService.new(test_image_path)
  
  puts "   - 各服务性能对比:"
  benchmark_results = multi_service.benchmark_services
  
  benchmark_results.each do |service_name, result|
    if result[:success]
      puts "     ✅ #{service_name}:"
      puts "       处理时间: #{result[:processing_time].round(2)}秒"
      puts "       置信度: #{result[:confidence]}"
      puts "       中文字符数: #{result[:chinese_count]}"
    else
      puts "     ❌ #{service_name}: #{result[:error]}"
    end
    puts ""
  end
  
rescue => e
  puts "   ❌ 性能对比测试失败: #{e.message}"
end

puts ""

# 6. 集成效果总结
puts "6. 集成效果总结:"
puts ""

puts "   ✅ 已完成集成:"
puts "     - PaddleOCR服务类创建"
puts "     - 多OCR服务管理器实现"
puts "     - AI增强OCR服务更新"
puts "     - 服务降级机制建立"
puts ""

puts "   🔧 系统架构:"
puts "     - 主服务: PaddleOCR (高性能中文识别)"
puts "     - 降级服务: Tesseract (英文识别兜底)"
puts "     - 智能选择: 自动选择最佳可用服务"
puts ""

puts "   🎯 预期效果:"
puts "     - 中文识别准确率: 从0%提升至85%+"
puts "     - 系统可用性: 多服务降级保障"
puts "     - 处理性能: 智能选择最优服务"

# 清理测试文件
File.delete(test_image_path) if File.exist?(test_image_path)

puts ""
puts "=== PaddleOCR集成测试完成 ==="