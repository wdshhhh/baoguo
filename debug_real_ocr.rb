#!/usr/bin/env ruby

# 真实面单OCR识别调试脚本
require_relative 'config/environment'

puts "=== 真实面单OCR识别问题诊断 ==="
puts ""

# 1. 检查服务器状态
puts "1. 服务器状态检查:"
puts ""

begin
  # 检查服务器是否运行 (支持rails server和puma)
  server_process = `ps aux | grep -E "(rails server|puma.*3000)" | grep -v grep`.strip
  if server_process.empty?
    puts "   ❌ Rails服务器未运行"
    puts "     请先启动服务器: rails server -b 0.0.0.0 -p 3000"
    exit(1)
  else
    puts "   ✅ Rails服务器正在运行"
  end

  # 检查端口
  port_check = `netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000`.strip
  if port_check.empty?
    puts "   ❌ 端口3000未监听"
  else
    puts "   ✅ 端口3000正在监听"
  end

rescue => e
  puts "   ❌ 服务器状态检查失败: #{e.message}"
end

puts ""

# 2. 检查API端点可访问性
puts "2. API端点可访问性检查:"
puts ""

begin
  require 'net/http'
  require 'uri'

  base_url = "http://localhost:3000"

  # 测试免认证OCR接口
  puts "   测试免认证OCR接口:"
  begin
    uri = URI.parse("#{base_url}/api/v1/ai/ocr_parcel_public")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'

    # 发送测试请求
    response = http.request(request)

    if response.code == "422" || response.code == "400"
      puts "     ✅ 免认证OCR接口存在 (HTTP #{response.code} - 缺少图片参数)"
    else
      puts "     ❌ 免认证OCR接口异常 (HTTP #{response.code})"
      puts "        响应内容: #{response.body}"
    end
  rescue => e
    puts "     ❌ 免认证OCR接口访问失败: #{e.message}"
  end

  # 测试增强OCR接口
  puts "   \n   测试增强OCR接口:"
  begin
    uri = URI.parse("#{base_url}/api/v1/ai/ocr_parcel_enhanced")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    if response.code == "401"
      puts "     ✅ 增强OCR接口存在 (HTTP 401 - 需要认证)"
    else
      puts "     ❌ 增强OCR接口异常 (HTTP #{response.code})"
    end
  rescue => e
    puts "     ❌ 增强OCR接口访问失败: #{e.message}"
  end

rescue => e
  puts "   ❌ API可访问性检查失败: #{e.message}"
end

puts ""

# 3. 创建真实面单模拟测试
puts "3. 真实面单模拟测试:"
puts ""

begin
  # 创建更真实的快递面单测试图片
  test_image_path = "/tmp/real_parcel_test_#{Time.now.to_i}.jpg"

  # 创建包含中文和快递信息的真实面单图片
  test_image = <<~PYTHON
import cv2
import numpy as np

# 创建白色背景
img = np.ones((600, 800, 3), dtype=np.uint8) * 255

# 添加快递公司Logo区域
cv2.rectangle(img, (50, 30), (200, 80), (0, 100, 0), -1)
cv2.putText(img, "顺丰速运", (60, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)

# 添加运单号
cv2.putText(img, "运单号: SF1234567890", (50, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)

# 添加收件人信息
cv2.putText(img, "收件人: 张三", (50, 160), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
cv2.putText(img, "电话: 13800138000", (50, 190), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
cv2.putText(img, "地址: 北京市朝阳区建国门外大街1号", (50, 220), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)

# 添加寄件人信息
cv2.putText(img, "寄件人: 李四", (50, 270), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
cv2.putText(img, "电话: 13900139000", (50, 300), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)

# 添加条形码区域
cv2.rectangle(img, (50, 350), (400, 450), (0, 0, 0), 2)
for i in range(20, 380, 10):
    height = np.random.randint(20, 80)
    cv2.rectangle(img, (50+i, 350), (50+i+5, 350+height), (0, 0, 0), -1)

# 添加二维码区域
cv2.rectangle(img, (450, 350), (550, 450), (0, 0, 0), 2)
for i in range(10):
    for j in range(10):
        if np.random.random() > 0.5:
            cv2.rectangle(img, (460+i*8, 360+j*8), (460+i*8+6, 360+j*8+6), (0, 0, 0), -1)

# 保存图片
cv2.imwrite("#{test_image_path}", img)
print("图片创建成功")
PYTHON

  script_path = "/tmp/create_real_parcel.py"
  File.write(script_path, test_image)

  puts "   创建真实面单测试图片..."
  output = `python3 #{script_path} 2>&1`
  File.delete(script_path) if File.exist?(script_path)

  if File.exist?(test_image_path)
    puts "   ✅ 真实面单测试图片创建成功: #{test_image_path}"
    puts "     图片大小: #{File.size(test_image_path)} bytes"

    # 直接测试FixedOcrService
    puts "   \n   直接测试FixedOcrService:"
    begin
      ocr_service = FixedOcrService.new(test_image_path)
      start_time = Time.now
      result = ocr_service.recognize
      processing_time = Time.now - start_time

      if result[:success]
        puts "     ✅ FixedOcrService识别成功 (耗时: #{processing_time.round(2)}秒)"
        puts "       识别文本: #{result[:raw_text].inspect}"
        puts "       置信度: #{result[:confidence]}"
        puts "       引擎: #{result[:engine]}"

        # 解析识别结果
        puts "   \n   解析识别结果:"
        parser = OcrResultParser.new(result[:raw_text])
        parsed_data = parser.parse

        puts "       运单号: #{parsed_data[:tracking_number]}"
        puts "       收件人: #{parsed_data[:recipient_name]}"
        puts "       电话: #{parsed_data[:recipient_phone]}"
        puts "       快递公司: #{parsed_data[:courier_company]}"
        puts "       地址: #{parsed_data[:recipient_address]}"

      else
        puts "     ❌ FixedOcrService识别失败: #{result[:error]}"
      end

    rescue => e
      puts "     ❌ FixedOcrService测试失败: #{e.message}"
      puts "        错误堆栈: #{e.backtrace.first(3).join('\n        ')}"
    end

    # 测试MultiOcrService
    puts "   \n   测试MultiOcrService:"
    begin
      multi_service = MultiOcrService.new(test_image_path)
      start_time = Time.now
      result = multi_service.recognize
      processing_time = Time.now - start_time

      if result[:success]
        puts "     ✅ MultiOcrService识别成功 (耗时: #{processing_time.round(2)}秒)"
        puts "       使用服务: #{result[:service_name]}"
        puts "       服务描述: #{result[:service_description]}"
        puts "       识别文本: #{result[:raw_text].inspect}"
        puts "       置信度: #{result[:confidence]}"
        puts "       中文字符数: #{result[:chinese_count]}"

        # 解析识别结果
        puts "   \n   解析识别结果:"
        parser = OcrResultParser.new(result[:raw_text])
        parsed_data = parser.parse

        puts "       运单号: #{parsed_data[:tracking_number]}"
        puts "       收件人: #{parsed_data[:recipient_name]}"
        puts "       电话: #{parsed_data[:recipient_phone]}"
        puts "       快递公司: #{parsed_data[:courier_company]}"
        puts "       地址: #{parsed_data[:recipient_address]}"

      else
        puts "     ❌ MultiOcrService识别失败: #{result[:error]}"
      end

    rescue => e
      puts "     ❌ MultiOcrService测试失败: #{e.message}"
      puts "        错误堆栈: #{e.backtrace.first(3).join('\n        ')}"
    end

    # 清理测试文件
    File.delete(test_image_path) if File.exist?(test_image_path)
  else
    puts "   ❌ 真实面单测试图片创建失败"
  end

rescue => e
  puts "   ❌ 真实面单模拟测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace.first(5).join('\n     ')}"
end

puts ""

# 4. 检查常见问题
puts "4. 常见问题排查:"
puts ""

begin
  # 检查图片上传限制
  puts "   图片上传限制检查:"

  # 检查Rails配置
  puts "   - 最大文件大小: 通常为10MB"
  puts "   - 允许的文件类型: image/*"

  # 检查前端上传组件
  puts "   \n   前端上传组件检查:"
  ocr_uploader_path = "app/javascript/packs/components/OcrUploader.vue"
  if File.exist?(ocr_uploader_path)
    content = File.read(ocr_uploader_path)

    # 检查文件大小限制
    if content.include?("10 * 1024 * 1024")
      puts "   ✅ 前端文件大小限制: 10MB"
    else
      puts "   ❌ 前端文件大小限制未设置或异常"
    end

    # 检查文件类型限制
    if content.include?("image/")
      puts "   ✅ 前端文件类型限制: image/*"
    else
      puts "   ❌ 前端文件类型限制未设置或异常"
    end

  else
    puts "   ❌ OCR上传组件不存在"
  end

  # 检查后端处理
  puts "   \n   后端处理检查:"
  ai_controller_path = "app/controllers/api/v1/ai_controller.rb"
  if File.exist?(ai_controller_path)
    content = File.read(ai_controller_path)

    if content.include?("ocr_parcel_public")
      puts "   ✅ 免认证OCR接口已实现"
    else
      puts "   ❌ 免认证OCR接口未实现"
    end

    if content.include?("params[:image]")
      puts "   ✅ 图片参数处理已实现"
    else
      puts "   ❌ 图片参数处理未实现"
    end

  else
    puts "   ❌ AI控制器不存在"
  end

rescue => e
  puts "   ❌ 常见问题排查失败: #{e.message}"
end

puts ""
puts "=== 真实面单OCR识别问题诊断完成 ==="
puts ""
puts "💡 如果仍然有问题，请检查:"
puts "1. 浏览器控制台是否有JavaScript错误"
puts "2. 网络请求是否成功发送"
puts "3. 服务器日志中的详细错误信息"
puts "4. 图片文件是否符合要求（大小、格式）"
