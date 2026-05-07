#!/usr/bin/env ruby

# 全面OCR系统调试脚本
require_relative 'config/environment'

puts "=== 全面OCR系统调试分析 ==="
puts ""

# 1. 检查系统环境
puts "1. 系统环境检查..."
puts ""

# 检查Tesseract
puts "   - Tesseract检查:"
tesseract_check = `which tesseract 2>/dev/null`
if tesseract_check.empty?
  puts "     ❌ Tesseract未安装"
else
  puts "     ✅ Tesseract已安装: #{tesseract_check.strip}"
  
  # 检查Tesseract版本和语言包
  version_check = `tesseract --version 2>&1`
  if version_check.include?("tesseract")
    puts "       版本信息: #{version_check.lines.first.strip}"
  else
    puts "       版本检查失败"
  end
  
  # 检查中文语言包
  lang_check = `tesseract --list-langs 2>&1`
  if lang_check.include?("chi_sim")
    puts "       ✅ 中文语言包已安装"
  else
    puts "       ❌ 中文语言包未安装"
  end
end

# 检查ImageMagick
puts ""
puts "   - ImageMagick检查:"
convert_check = `which convert 2>/dev/null`
if convert_check.empty?
  puts "     ❌ ImageMagick未安装"
else
  puts "     ✅ ImageMagick已安装: #{convert_check.strip}"
  
  # 检查ImageMagick版本
  version_check = `convert --version 2>&1`
  if version_check.include?("ImageMagick")
    puts "       版本信息: #{version_check.lines.first.strip}"
  else
    puts "       版本检查失败"
  end
end

puts ""

# 2. 检查Ruby依赖
puts "2. Ruby依赖检查..."
puts ""

# 检查关键gem
required_gems = ['rtesseract', 'mini_magick', 'rmagick']
required_gems.each do |gem_name|
  begin
    gem gem_name
    puts "     ✅ #{gem_name}: 已安装"
  rescue LoadError
    puts "     ❌ #{gem_name}: 未安装"
  end
end

puts ""

# 3. 检查OCR服务类
puts "3. OCR服务类检查..."
puts ""

# 检查所有OCR相关类
ocr_classes = ['FixedOcrService', 'AiEnhancedOcrService', 'OcrResultParser', 'DemoOcrService']
ocr_classes.each do |class_name|
  begin
    klass = Object.const_get(class_name)
    puts "     ✅ #{class_name}: 类存在"
    
    # 检查实例化
    if class_name == 'FixedOcrService'
      instance = klass.new("/tmp/test.jpg")
      puts "       实例化: 成功"
    else
      instance = klass.new
      puts "       实例化: 成功"
    end
    
  rescue => e
    puts "     ❌ #{class_name}: 类不存在或实例化失败 - #{e.message}"
  end
end

puts ""

# 4. 检查API控制器
puts "4. API控制器检查..."
puts ""

begin
  ai_controller = Api::V1::AiController.new
  puts "     ✅ AiController: 控制器存在"
  
  # 检查方法
  methods = ['ocr_parcel', 'ocr_parcel_enhanced']
  methods.each do |method|
    if ai_controller.respond_to?(method)
      puts "       ✅ #{method}: 方法存在"
    else
      puts "       ❌ #{method}: 方法不存在"
    end
  end
  
rescue => e
  puts "     ❌ AiController检查失败: #{e.message}"
end

puts ""

# 5. 检查路由配置
puts "5. 路由配置检查..."
puts ""

begin
  routes = Rails.application.routes.routes.map do |route|
    path = route.path.spec.to_s
    verb = route.verb
    { path: path, verb: verb } if path.include?('ocr') || path.include?('ai')
  end.compact
  
  puts "     ✅ OCR相关路由:"
  routes.each do |route|
    puts "       #{route[:verb]} #{route[:path]}"
  end
  
  # 检查关键路由是否存在
  critical_routes = [
    { verb: 'POST', path: '/api/v1/ai/ocr_parcel' },
    { verb: 'POST', path: '/api/v1/ai/ocr_parcel_enhanced' }
  ]
  
  critical_routes.each do |critical|
    exists = routes.any? { |r| r[:verb] == critical[:verb] && r[:path] == critical[:path] }
    if exists
      puts "       ✅ 关键路由 #{critical[:verb]} #{critical[:path]}: 存在"
    else
      puts "       ❌ 关键路由 #{critical[:verb]} #{critical[:path]}: 不存在"
    end
  end
  
rescue => e
  puts "     ❌ 路由检查失败: #{e.message}"
end

puts ""

# 6. 检查数据库模型
puts "6. 数据库模型检查..."
puts ""

begin
  # 检查Package模型
  if defined?(Package)
    puts "     ✅ Package模型: 存在"
    
    # 检查字段
    package_fields = Package.column_names
    required_fields = ['tracking_number', 'recipient_name', 'recipient_phone', 'courier_company']
    
    required_fields.each do |field|
      if package_fields.include?(field)
        puts "       ✅ #{field}: 字段存在"
      else
        puts "       ❌ #{field}: 字段不存在"
      end
    end
  else
    puts "     ❌ Package模型: 不存在"
  end
  
  # 检查OcrRecord模型
  if defined?(OcrRecord)
    puts "     ✅ OcrRecord模型: 存在"
  else
    puts "     ❌ OcrRecord模型: 不存在"
  end
  
rescue => e
  puts "     ❌ 数据库模型检查失败: #{e.message}"
end

puts ""

# 7. 检查前端组件
puts "7. 前端组件检查..."
puts ""

# 检查前端文件是否存在
frontend_files = [
  'app/javascript/packs/components/OcrUploader.vue',
  'app/javascript/packs/components/PackageOcrUploader.vue',
  'app/javascript/packs/views/pc/Packages.vue',
  'app/javascript/packs/views/mobile/Packages.vue'
]

frontend_files.each do |file_path|
  if File.exist?(file_path)
    puts "     ✅ #{file_path}: 文件存在"
    
    # 检查文件内容
    content = File.read(file_path)
    
    # 检查关键API调用
    if content.include?('/api/v1/ai/ocr_parcel_enhanced')
      puts "       ✅ 调用修复后的API接口"
    elsif content.include?('/api/v1/ai/ocr_parcel')
      puts "       ⚠️ 调用旧的API接口"
    else
      puts "       ❌ 未找到API调用"
    end
    
    # 检查错误处理
    if content.include?('error') || content.include?('catch')
      puts "       ✅ 包含错误处理"
    else
      puts "       ⚠️ 缺少错误处理"
    end
    
  else
    puts "     ❌ #{file_path}: 文件不存在"
  end
end

puts ""

# 8. 检查系统配置
puts "8. 系统配置检查..."
puts ""

# 检查环境变量
env_vars = ['RAILS_ENV', 'DATABASE_URL', 'TESSERACT_PATH']
env_vars.each do |var|
  value = ENV[var]
  if value
    puts "     ✅ #{var}: 已设置 (#{value[0..50]}...)"
  else
    puts "     ⚠️ #{var}: 未设置"
  end
end

# 检查配置文件
config_files = ['config/database.yml', 'config/routes.rb', 'config/application.rb']
config_files.each do |file_path|
  if File.exist?(file_path)
    puts "     ✅ #{file_path}: 配置文件存在"
  else
    puts "     ❌ #{file_path}: 配置文件不存在"
  end
end

puts ""

# 9. 检查临时目录权限
puts "9. 文件系统权限检查..."
puts ""

# 检查临时目录
temp_dirs = ['/tmp', 'tmp/ocr_uploads', 'public/uploads']
temp_dirs.each do |dir|
  if File.directory?(dir)
    # 检查写权限
    test_file = File.join(dir, "test_permission_#{Time.now.to_i}.txt")
    begin
      File.write(test_file, "test")
      File.delete(test_file)
      puts "     ✅ #{dir}: 可写"
    rescue => e
      puts "     ❌ #{dir}: 不可写 - #{e.message}"
    end
  else
    puts "     ❌ #{dir}: 目录不存在"
  end
end

puts ""

# 10. 综合测试
puts "10. 综合功能测试..."
puts ""

begin
  # 创建测试图片
  test_image_path = "/tmp/comprehensive_test_#{Time.now.to_i}.jpg"
  system("convert -size 400x300 xc:white -pointsize 18 -fill black -gravity center -annotate +0+0 '顺丰快递 SF1234567890\\n收件人: 李四\\n手机: 13900139000\\n地址: 上海市浦东新区陆家嘴金融中心' #{test_image_path}")
  
  if File.exist?(test_image_path)
    puts "     ✅ 测试图片创建成功"
    
    # 模拟上传文件
    class MockImage
      attr_reader :original_filename
      
      def initialize(path)
        @path = path
        @original_filename = File.basename(path)
      end
      
      def read
        File.binread(@path)
      end
      
      def size
        File.size(@path)
      end
    end
    
    mock_image = MockImage.new(test_image_path)
    
    # 测试完整OCR流程
    puts "     - 测试完整OCR流程..."
    
    ai_service = AiEnhancedOcrService.new
    result = ai_service.recognize_parcel_with_ai(mock_image)
    
    if result[:success]
      puts "       ✅ OCR识别成功"
      
      data = result[:data]
      puts "         运单号: #{data[:tracking_number] || 'nil'}"
      puts "         收件人: #{data[:recipient_name] || 'nil'}"
      puts "         手机号: #{data[:recipient_phone] || 'nil'}"
      puts "         快递公司: #{data[:courier_company] || 'nil'}"
      puts "         地址: #{data[:recipient_address] || 'nil'}"
      
      # 验证数据质量
      valid_fields = data.select { |k, v| v && !v.to_s.empty? }.size
      total_fields = data.size
      quality_score = (valid_fields.to_f / total_fields * 100).round(2)
      
      puts "         数据质量: #{quality_score}%"
      
      if quality_score >= 60
        puts "         ✅ 数据质量良好"
      else
        puts "         ⚠️ 数据质量较低"
      end
      
    else
      puts "       ❌ OCR识别失败: #{result[:error]}"
    end
    
    # 清理测试文件
    File.delete(test_image_path)
    
  else
    puts "     ❌ 测试图片创建失败"
  end
  
rescue => e
  puts "     ❌ 综合测试失败: #{e.message}"
  puts "       错误堆栈: #{e.backtrace[0..3].join('\n        ')}"
end

puts ""
puts "=== 全面调试完成 ==="
puts ""
puts "问题总结:"
puts "1. 检查系统环境和依赖"
puts "2. 验证服务类和API接口"
puts "3. 检查数据库模型和配置"
puts "4. 测试完整功能流程"
puts ""
puts "下一步行动:"
puts "根据检查结果修复发现的所有问题"