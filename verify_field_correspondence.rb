#!/usr/bin/env ruby

# 全面验证前后端字段对应关系
require_relative 'config/environment'

puts "=== 全面验证前后端字段对应关系 ==="
puts ""

# 1. 后端AI服务返回字段
puts "1. 后端AI服务返回字段 (ai_enhanced_ocr_service.rb):"
ai_service_fields = []

begin
  ai_service_code = File.read('/home/wjc/桌面/yizhan/app/services/ai_enhanced_ocr_service.rb')
  
  # 查找data字段定义
  data_pattern = /data: \{\s*([^}]+)\s*\}/
  if match = ai_service_code.match(data_pattern)
    fields_section = match[1]
    fields = fields_section.scan(/(\w+):/).flatten
    
    puts "   后端返回字段: #{fields.join(', ')}"
    ai_service_fields = fields
  else
    puts "   ❌ 无法找到data字段定义"
  end
rescue => e
  puts "   ❌ 读取AI服务文件失败: #{e.message}"
end

puts ""

# 2. 前端接收字段
puts "2. 前端接收字段 (OcrUploader.vue):"
frontend_receive_fields = []

begin
  frontend_code = File.read('/home/wjc/桌面/yizhan/app/javascript/packs/components/OcrUploader.vue')
  
  # 查找ocrResult.value赋值
  if frontend_code.include?('ocrResult.value = response.data.data')
    puts "   ✅ 前端正确接收后端数据: ocrResult.value = response.data.data"
  else
    puts "   ❌ 前端数据接收方式不正确"
  end
  
  # 检查前端是否使用了所有后端字段
  ai_service_fields.each do |field|
    if frontend_code.include?("ocrResult.#{field}")
      puts "   ✅ #{field}: 前端已使用"
      frontend_receive_fields << field
    else
      puts "   ❌ #{field}: 前端未使用"
    end
  end
rescue => e
  puts "   ❌ 读取前端文件失败: #{e.message}"
end

puts ""

# 3. 前端显示字段
puts "3. 前端显示字段 (OcrUploader.vue模板):"
frontend_display_fields = []

begin
  # 查找模板中的v-model绑定
  template_section = frontend_code.match(/<template>([\s\S]*?)<\/template>/)
  
  if template_section
    template = template_section[1]
    
    # 查找所有v-model="ocrResult.字段名"
    v_model_pattern = /v-model="ocrResult\.(\w+)"/
    display_fields = template.scan(v_model_pattern).flatten
    
    puts "   前端显示字段: #{display_fields.join(', ')}"
    frontend_display_fields = display_fields
    
    # 检查显示字段是否完整
    ai_service_fields.each do |field|
      if display_fields.include?(field)
        puts "   ✅ #{field}: 前端显示正确"
      else
        puts "   ❌ #{field}: 前端未显示"
      end
    end
  else
    puts "   ❌ 无法找到模板部分"
  end
rescue => e
  puts "   ❌ 分析前端模板失败: #{e.message}"
end

puts ""

# 4. 手动输入部分字段检查
puts "4. 手动输入字段一致性检查:"

begin
  # 查找手动输入部分的字段定义
  manual_input_pattern = /ocrResult\.value = \{[\s\S]*?\}/
  if match = frontend_code.match(manual_input_pattern)
    manual_fields = match[0].scan(/(\w+):/).flatten
    
    puts "   手动输入字段: #{manual_fields.join(', ')}"
    
    # 检查手动输入字段是否与后端一致
    manual_fields.each do |field|
      if ai_service_fields.include?(field)
        puts "   ✅ #{field}: 手动输入字段与后端一致"
      else
        puts "   ⚠️  #{field}: 手动输入字段与后端不一致"
      end
    end
  else
    puts "   ℹ️  未找到手动输入部分"
  end
rescue => e
  puts "   ❌ 检查手动输入字段失败: #{e.message}"
end

puts ""

# 5. 事件发射字段检查
puts "5. 事件发射字段检查:"

begin
  # 查找emit事件
  emit_pattern = /emit\('ocr-result', ocrResult\.value\)/
  if frontend_code.match(emit_pattern)
    puts "   ✅ 事件发射正确: emit('ocr-result', ocrResult.value)"
    puts "   ℹ️  发射整个ocrResult对象，包含所有字段"
  else
    puts "   ❌ 事件发射方式不正确"
  end
rescue => e
  puts "   ❌ 检查事件发射失败: #{e.message}"
end

puts ""

# 6. 字段对应关系总结
puts "6. 字段对应关系总结:"

# 检查所有字段是否一一对应
all_fields_match = true

puts "   后端字段 → 前端接收 → 前端显示"
ai_service_fields.each do |field|
  receive_ok = frontend_receive_fields.include?(field)
  display_ok = frontend_display_fields.include?(field)
  
  status = "✅" if receive_ok && display_ok
  status = "❌" unless receive_ok && display_ok
  
  puts "     #{status} #{field.ljust(20)} #{receive_ok ? '✅接收' : '❌未接收'} #{display_ok ? '✅显示' : '❌未显示'}"
  
  all_fields_match = false unless receive_ok && display_ok
end

puts ""

# 7. 测试实际数据流
puts "7. 实际数据流测试:"

begin
  # 创建测试图片
  require 'mini_magick'
  
  image = MiniMagick::Tool::Convert.new do |convert|
    convert.size '600x400'
    convert.xc 'white'
    convert.font 'DejaVu-Sans'
    convert.pointsize 20
    convert.fill 'black'
    convert.gravity 'northwest'
    convert.annotate '+50+50', '顺丰快递 SF1234567890'
    convert.annotate '+50+100', '收件人: 张三'
    convert.annotate '+50+150', '手机号: 13800138000'
    convert.annotate '+50+200', '地址: 北京市朝阳区'
    convert << '/tmp/test_correspondence.jpg'
  end
  
  # 模拟后端处理
  ai_service = AiEnhancedOcrService.new
  backend_result = ai_service.recognize_parcel_with_ai('/tmp/test_correspondence.jpg')
  
  if backend_result[:success]
    backend_data = backend_result[:data]
    
    puts "   后端实际返回数据:"
    backend_data.each do |key, value|
      puts "     #{key}: #{value.inspect}"
    end
    
    # 检查前端是否能处理这些字段
    missing_fields = backend_data.keys.map(&:to_s) - frontend_display_fields
    
    if missing_fields.empty?
      puts "   ✅ 前端能处理所有后端返回字段"
    else
      puts "   ❌ 前端缺少字段: #{missing_fields.join(', ')}"
    end
  else
    puts "   ❌ 后端处理失败: #{backend_result[:error]}"
  end
  
rescue => e
  puts "   ❌ 实际数据流测试失败: #{e.message}"
end

puts ""
puts "=== 验证完成 ==="
puts ""

if all_fields_match
  puts "🎉 所有字段一一对应，数据流畅通！"
else
  puts "⚠️  存在字段不匹配问题，需要修复"
end

puts ""
puts "建议:"
puts "- 确保后端返回字段与前端期望字段完全一致"
puts "- 检查前端模板是否显示所有必要字段"
puts "- 验证事件发射是否包含完整数据"