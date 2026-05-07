#!/usr/bin/env ruby

# OCR功能诊断脚本 - 分析测试脚本成功但服务器无法启用的问题
require_relative 'config/environment'

puts "=== OCR功能问题诊断 ==="
puts ""

# 1. 检查服务器运行状态
puts "1. 服务器运行状态检查:"
puts ""

begin
  # 检查Rails服务器进程
  server_process = `ps aux | grep "rails server" | grep -v grep`.strip
  if server_process.empty?
    puts "   ❌ Rails服务器未运行"
  else
    puts "   ✅ Rails服务器正在运行"
    puts "     进程信息: #{server_process.split('\n').first}"
  end

  # 检查Puma进程
  puma_process = `ps aux | grep puma | grep -v grep`.strip
  if puma_process.empty?
    puts "   ❌ Puma进程未运行"
  else
    puts "   ✅ Puma进程正在运行"
    puma_process.split("\n").each do |process|
      puts "     - #{process}" if process.include?("puma")
    end
  end

  # 检查端口占用
  port_check = `netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000`.strip
  if port_check.empty?
    puts "   ❌ 端口3000未监听"
  else
    puts "   ✅ 端口3000正在监听"
    puts "     #{port_check}"
  end

rescue => e
  puts "   ❌ 服务器状态检查失败: #{e.message}"
end

puts ""

# 2. 检查前端访问状态
puts "2. 前端访问状态检查:"
puts ""

begin
  # 检查前端资源
  public_dir = "public/packs"
  if Dir.exist?(public_dir)
    puts "   ✅ 前端资源目录存在"

    # 检查主要JS文件
    js_files = Dir.glob("#{public_dir}/**/*.js").first(3)
    if js_files.any?
      puts "   ✅ 前端JS文件存在"
      js_files.each do |file|
        puts "     - #{File.basename(file)} (#{File.size(file)} bytes)"
      end
    else
      puts "   ❌ 前端JS文件不存在"
    end

  else
    puts "   ❌ 前端资源目录不存在"
  end

  # 检查前端编译状态
  manifest_path = "public/packs/manifest.json"
  if File.exist?(manifest_path)
    puts "   ✅ Webpack manifest文件存在"

    begin
      manifest = JSON.parse(File.read(manifest_path))
      puts "   ✅ Manifest文件格式正确"
      puts "     包含 #{manifest.keys.size} 个资源条目"
    rescue => e
      puts "   ❌ Manifest文件格式错误: #{e.message}"
    end
  else
    puts "   ❌ Webpack manifest文件不存在"
  end

rescue => e
  puts "   ❌ 前端状态检查失败: #{e.message}"
end

puts ""

# 3. 检查OCR API端点可访问性
puts "3. API端点可访问性检查:"
puts ""

begin
  # 创建测试HTTP请求
  require 'net/http'
  require 'uri'

  # 测试基础API端点
  base_url = "http://localhost:3000"

  # 测试根路径
  begin
    response = Net::HTTP.get_response(URI.parse("#{base_url}/"))
    if response.code == "200"
      puts "   ✅ 根路径可访问 (HTTP 200)"
    else
      puts "   ❌ 根路径不可访问 (HTTP #{response.code})"
    end
  rescue => e
    puts "   ❌ 根路径访问失败: #{e.message}"
  end

  # 测试API健康检查
  begin
    response = Net::HTTP.get_response(URI.parse("#{base_url}/api/v1/health"))
    if response.code == "200"
      puts "   ✅ API健康检查可访问 (HTTP 200)"
    else
      puts "   ⚠️ API健康检查不可访问 (HTTP #{response.code})"
    end
  rescue => e
    puts "   ⚠️ API健康检查访问失败: #{e.message}"
  end

  # 测试OCR API端点
  begin
    uri = URI.parse("#{base_url}/api/v1/ai/ocr_parcel")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5

    # 创建测试请求
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'

    # 发送空请求测试端点是否存在
    response = http.request(request)

    if response.code == "422" || response.code == "400"
      puts "   ✅ OCR API端点存在 (HTTP #{response.code} - 缺少参数)"
    elsif response.code == "200"
      puts "   ✅ OCR API端点可访问 (HTTP 200)"
    else
      puts "   ❌ OCR API端点异常 (HTTP #{response.code})"
    end

  rescue => e
    puts "   ❌ OCR API端点访问失败: #{e.message}"
  end

rescue => e
  puts "   ❌ API可访问性检查失败: #{e.message}"
end

puts ""

# 4. 检查前端OCR组件
puts "4. 前端OCR组件检查:"
puts ""

begin
  # 检查OCR上传组件
  ocr_uploader_path = "app/javascript/packs/components/OcrUploader.vue"
  if File.exist?(ocr_uploader_path)
    puts "   ✅ OCR上传组件存在"

    # 检查组件内容
    content = File.read(ocr_uploader_path)

    if content.include?("ocr_parcel")
      puts "   ✅ 组件包含OCR API调用"
    else
      puts "   ❌ 组件缺少OCR API调用"
    end

    if content.include?("@change")
      puts "   ✅ 组件包含文件上传事件"
    else
      puts "   ❌ 组件缺少文件上传事件"
    end

  else
    puts "   ❌ OCR上传组件不存在"
  end

  # 检查主应用文件
  app_js_path = "app/javascript/packs/app.js"
  if File.exist?(app_js_path)
    puts "   ✅ 主应用JS文件存在"

    content = File.read(app_js_path)
    if content.include?("OcrUploader")
      puts "   ✅ 主应用包含OCR组件引用"
    else
      puts "   ❌ 主应用缺少OCR组件引用"
    end

  else
    puts "   ❌ 主应用JS文件不存在"
  end

rescue => e
  puts "   ❌ 前端组件检查失败: #{e.message}"
end

puts ""

# 5. 检查实际OCR功能测试
puts "5. 实际OCR功能测试:"
puts ""

begin
  # 创建测试图片
  test_image_path = "/tmp/diagnose_ocr_test_#{Time.now.to_i}.jpg"

  # 创建包含中文的测试图片
  test_image = <<~PYTHON
import cv2
import numpy as np

# 创建白色背景
img = np.ones((300, 600, 3), dtype=np.uint8) * 255

# 添加测试文本（包含中文）
cv2.putText(img, "顺丰快递 SF1234567890", (50, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2)
cv2.putText(img, "收件人: 张三", (50, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
cv2.putText(img, "电话: 13800138000", (50, 160), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
cv2.putText(img, "地址: 北京市朝阳区", (50, 200), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)

# 保存图片
cv2.imwrite("#{test_image_path}", img)
PYTHON

  script_path = "/tmp/create_diagnose_image.py"
  File.write(script_path, test_image)
  `python3 #{script_path} 2>&1`
  File.delete(script_path) if File.exist?(script_path)

  if File.exist?(test_image_path)
    puts "   ✅ 测试图片创建成功: #{test_image_path}"

    # 测试直接调用OCR服务
    puts "   \n   直接调用FixedOcrService:"
    ocr_service = FixedOcrService.new(test_image_path)
    result = ocr_service.recognize

    if result[:success]
      puts "     ✅ 直接调用成功"
      puts "       识别文本: #{result[:raw_text].inspect}"
      puts "       置信度: #{result[:confidence]}"
      puts "       引擎: #{result[:engine]}"
    else
      puts "     ❌ 直接调用失败: #{result[:error]}"
    end

    # 测试通过API调用
    puts "   \n   模拟API调用:"
    begin
      # 模拟AI控制器调用
      ai_service = AiEnhancedOcrService.new

      # 模拟文件上传
      file = File.open(test_image_path)
      api_result = ai_service.recognize_parcel_with_ai(file)
      file.close

      if api_result[:success]
        puts "     ✅ API模拟调用成功"
        puts "       运单号: #{api_result[:data][:tracking_number]}"
        puts "       收件人: #{api_result[:data][:recipient_name]}"
        puts "       电话: #{api_result[:data][:recipient_phone]}"
        puts "       快递公司: #{api_result[:data][:courier_company]}"
      else
        puts "     ❌ API模拟调用失败: #{api_result[:error]}"
      end

    rescue => e
      puts "     ❌ API模拟调用异常: #{e.message}"
      puts "        错误堆栈: #{e.backtrace.first(3).join('\n        ')}"
    end

    # 清理测试文件
    File.delete(test_image_path) if File.exist?(test_image_path)
  else
    puts "   ❌ 测试图片创建失败"
  end

rescue => e
  puts "   ❌ 实际功能测试失败: #{e.message}"
  puts "     错误堆栈: #{e.backtrace.first(5).join('\n     ')}"
end

puts ""

# 6. 常见问题排查
puts "6. 常见问题排查:"
puts ""

begin
  # 检查Gemfile依赖
  gemfile_path = "Gemfile"
  if File.exist?(gemfile_path)
    content = File.read(gemfile_path)

    if content.include?("rtesseract")
      puts "   ✅ rtesseract gem已配置"
    else
      puts "   ❌ rtesseract gem未配置"
    end

    if content.include?("mini_magick")
      puts "   ✅ mini_magick gem已配置"
    else
      puts "   ❌ mini_magick gem未配置"
    end
  end

  # 检查环境变量
  puts "   \n   环境变量检查:"

  # 检查TESSDATA_PREFIX
  tessdata_prefix = ENV['TESSDATA_PREFIX']
  if tessdata_prefix
    puts "     ✅ TESSDATA_PREFIX: #{tessdata_prefix}"
  else
    puts "     ⚠️ TESSDATA_PREFIX未设置"
  end

  # 检查PATH中的Tesseract
  path_dirs = ENV['PATH'].split(':')
  tesseract_found = path_dirs.any? { |dir| File.exist?("#{dir}/tesseract") }
  if tesseract_found
    puts "     ✅ Tesseract在PATH中"
  else
    puts "     ⚠️ Tesseract不在PATH中"
  end

rescue => e
  puts "   ❌ 常见问题排查失败: #{e.message}"
end

puts ""
puts "=== OCR功能问题诊断完成 ==="
puts ""
puts "💡 建议:"
puts "1. 检查浏览器控制台是否有JavaScript错误"
puts "2. 确认前端是否正确加载了OCR组件"
puts "3. 检查网络请求是否成功发送到OCR API"
puts "4. 查看Rails服务器日志中的详细错误信息"
