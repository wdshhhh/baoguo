#!/usr/bin/env ruby

# 全面系统诊断脚本
require_relative 'config/environment'

puts "=== 全面系统诊断 ==="
puts ""

# 1. 检查服务器状态
puts "1. 服务器状态检查:"
begin
  # 检查Rails服务器进程
  server_process = `ps aux | grep -E "(rails server|puma.*3000)" | grep -v grep`.strip
  if server_process.empty?
    puts "   ❌ Rails服务器未运行"
  else
    puts "   ✅ Rails服务器运行中"
    puts "     进程信息: #{server_process.split[1..2].join(' ')}"
  end
  
  # 检查端口占用
  port_check = `netstat -tulpn 2>/dev/null | grep :3000`.strip
  if port_check.empty?
    puts "   ❌ 端口3000未监听"
  else
    puts "   ✅ 端口3000监听中"
  end
  
rescue => e
  puts "   ❌ 服务器状态检查失败: #{e.message}"
end

puts ""

# 2. 检查OCR服务完整性
puts "2. OCR服务完整性检查:"
begin
  # 检查OCR服务类是否存在
  services_to_check = [
    'FixedOcrService',
    'AiEnhancedOcrService', 
    'MultiOcrService',
    'OptimizedOcrService',
    'OcrResultParser'
  ]
  
  services_to_check.each do |service_name|
    if Object.const_defined?(service_name)
      puts "   ✅ #{service_name} 存在"
    else
      puts "   ❌ #{service_name} 不存在"
    end
  end
  
  # 测试OCR服务实例化
  puts ""
  puts "   测试OCR服务实例化:"
  
  # 创建测试图片
  require 'mini_magick'
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x300'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 16
    convert.fill 'black'
    convert.gravity 'center'
    convert.annotate '0,0', '测试快递 YD123456789 13800138000'
    convert << '/tmp/test_diagnostic.jpg'
  end
  
  puts "   ✅ 测试图片创建成功: /tmp/test_diagnostic.jpg"
  
  # 测试优化OCR服务
  puts ""
  puts "   测试优化OCR服务:"
  optimized_service = OptimizedOcrService.new('/tmp/test_diagnostic.jpg')
  result = optimized_service.recognize
  
  puts "   识别结果: #{result[:success] ? '成功' : '失败'}"
  puts "   使用引擎: #{result[:engine]}"
  puts "   处理时间: #{result[:processing_time].round(2)}秒"
  
  if result[:success]
    puts "   识别文本: #{result[:raw_text][0..100]}..."
  else
    puts "   错误信息: #{result[:error]}"
  end
  
rescue => e
  puts "   ❌ OCR服务检查失败: #{e.message}"
  puts "   错误堆栈: #{e.backtrace[0..3].join('\n   ')}"
end

puts ""

# 3. 检查API接口
puts "3. API接口检查:"
begin
  # 检查API控制器
  controllers_to_check = [
    'Api::V1::AiController',
    'Api::V1::BaseController'
  ]
  
  controllers_to_check.each do |controller_name|
    if Object.const_defined?(controller_name)
      puts "   ✅ #{controller_name} 存在"
    else
      puts "   ❌ #{controller_name} 不存在"
    end
  end
  
  # 检查API方法
  puts ""
  puts "   检查API方法:"
  ai_controller = Api::V1::AiController.new
  methods_to_check = ['ocr_parcel_public', 'ocr_parcel_enhanced']
  
  methods_to_check.each do |method_name|
    if ai_controller.respond_to?(method_name, true)
      puts "   ✅ #{method_name} 方法存在"
    else
      puts "   ❌ #{method_name} 方法不存在"
    end
  end
  
rescue => e
  puts "   ❌ API接口检查失败: #{e.message}"
end

puts ""

# 4. 检查前端资源
puts "4. 前端资源检查:"
begin
  # 检查关键前端文件
  frontend_files = [
    'app/javascript/packs/views/pc/Packages.vue',
    'app/javascript/packs/components/PackageOcrUploader.vue',
    'app/javascript/packs/app.js',
    'public/packs/manifest.json'
  ]
  
  frontend_files.each do |file_path|
    if File.exist?(file_path)
      puts "   ✅ #{file_path} 存在"
    else
      puts "   ❌ #{file_path} 不存在"
    end
  end
  
  # 检查Webpack编译
  puts ""
  puts "   检查Webpack编译:"
  manifest_path = 'public/packs/manifest.json'
  if File.exist?(manifest_path)
    manifest = JSON.parse(File.read(manifest_path))
    puts "   ✅ Webpack清单文件存在"
    puts "     包含 #{manifest.keys.size} 个资源"
  else
    puts "   ❌ Webpack清单文件不存在"
  end
  
rescue => e
  puts "   ❌ 前端资源检查失败: #{e.message}"
end

puts ""

# 5. 检查数据库连接
puts "5. 数据库连接检查:"
begin
  # 测试数据库连接
  ActiveRecord::Base.connection.execute('SELECT 1')
  puts "   ✅ 数据库连接正常"
  
  # 检查关键表
  tables_to_check = ['packages', 'users']
  tables_to_check.each do |table_name|
    if ActiveRecord::Base.connection.table_exists?(table_name)
      puts "   ✅ #{table_name} 表存在"
    else
      puts "   ❌ #{table_name} 表不存在"
    end
  end
  
rescue => e
  puts "   ❌ 数据库连接检查失败: #{e.message}"
end

puts ""

# 6. 检查系统依赖
puts "6. 系统依赖检查:"
begin
  # 检查关键依赖
  dependencies = [
    { name: 'Tesseract', command: 'which tesseract' },
    { name: 'ImageMagick', command: 'which convert' },
    { name: 'Python3', command: 'which python3' },
    { name: 'PaddleOCR', command: 'python3 -c "import paddleocr; print(\"OK\")"' }
  ]
  
  dependencies.each do |dep|
    result = `#{dep[:command]} 2>&1`.strip
    if $?.success?
      puts "   ✅ #{dep[:name]} 可用"
    else
      puts "   ❌ #{dep[:name]} 不可用"
    end
  end
  
rescue => e
  puts "   ❌ 系统依赖检查失败: #{e.message}"
end

puts ""

# 7. 问题诊断建议
puts "7. 问题诊断建议:"
puts "   如果系统仍有问题，请检查以下方面:"
puts "   - 浏览器控制台错误信息 (F12 → Console)"
puts "   - Rails服务器日志 (log/development.log)"
puts "   - 前端JavaScript错误"
puts "   - 网络请求状态 (F12 → Network)"
puts "   - API响应数据格式"

puts ""
puts "=== 诊断完成 ==="