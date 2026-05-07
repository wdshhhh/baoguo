#!/usr/bin/env ruby

# 中文OCR识别修复效果验证
require_relative 'config/environment'

puts "=== 中文OCR识别修复效果验证 ==="
puts ""

# 1. 检查Tesseract中文语言包状态
puts "1. Tesseract中文语言包状态检查:"
puts ""

begin
  # 检查语言包
  lang_list = `tesseract --list-langs 2>&1`
  
  if lang_list.include?("chi_sim")
    puts "   ✅ 简体中文语言包已安装"
  else
    puts "   ❌ 简体中文语言包未安装"
  end
  
  if lang_list.include?("chi_tra")
    puts "   ✅ 繁体中文语言包已安装"
  else
    puts "   ❌ 繁体中文语言包未安装"
  end
  
  # 测试中文识别
  puts ""
  puts "   - 中文识别能力测试:"
  
  chinese_test_path = "/tmp/chinese_fixed_test_#{Time.now.to_i}.jpg"
  
  # 创建清晰的中文测试图片
  system("convert -size 600x400 xc:white -pointsize 28 -fill black -gravity center -annotate +0+0 '顺丰快递\\n运单号: SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{chinese_test_path}")
  
  if File.exist?(chinese_test_path)
    puts "     ✅ 中文测试图片创建成功"
    
    # 测试不同语言组合
    language_combinations = [
      { lang: 'chi_sim', desc: '简体中文' },
      { lang: 'chi_sim+eng', desc: '简体中文+英文' }
    ]
    
    language_combinations.each do |combo|
      puts "     - 测试语言: #{combo[:desc]} (#{combo[:lang]})"
      
      begin
        tesseract_cmd = "tesseract #{chinese_test_path} stdout -l #{combo[:lang]} --psm 6 2>&1"
        result = `#{tesseract_cmd}`.strip
        
        if result && !result.empty?
          puts "       ✅ 识别成功"
          puts "         识别结果: #{result[0..100]}..."
          
          # 统计中文字符
          chinese_chars = result.scan(/[\u4e00-\u9fa5]/)
          puts "         中文字符数: #{chinese_chars.size}"
          
          if chinese_chars.size > 0
            puts "         识别到的中文: #{chinese_chars.uniq.join(', ')}"
          else
            puts "         ⚠️ 未识别到中文字符"
          end
          
        else
          puts "       ❌ 识别失败或结果为空"
        end
        
      rescue => e
        puts "       ❌ 调用失败: #{e.message}"
      end
      
      puts ""
    end
    
    # 清理测试文件
    File.delete(chinese_test_path)
    
  else
    puts "     ❌ 中文测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ 语言包检查失败: #{e.message}"
end

puts ""

# 2. 测试系统OCR服务
puts "2. 系统OCR服务测试:"
puts ""

begin
  # 创建中文测试图片
  system_test_path = "/tmp/system_chinese_test_#{Time.now.to_i}.jpg"
  system("convert -size 600x400 xc:white -pointsize 28 -fill black -gravity center -annotate +0+0 '顺丰快递\\n运单号: SF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区建国路88号' #{system_test_path}")
  
  if File.exist?(system_test_path)
    puts "   ✅ 系统测试图片创建成功"
    
    # 使用FixedOcrService
    ocr_service = FixedOcrService.new(system_test_path)
    ocr_result = ocr_service.recognize
    
    if ocr_result[:success]
      puts "   ✅ OCR识别成功"
      puts "     引擎: #{ocr_result[:engine]}"
      puts "     置信度: #{ocr_result[:confidence]}"
      puts ""
      
      # 检查中文识别效果
      chinese_chars = ocr_result[:raw_text].scan(/[\u4e00-\u9fa5]/)
      
      if chinese_chars.size > 0
        puts "   ✅ 系统识别到中文字符: #{chinese_chars.size}个"
        puts "     识别到的中文: #{chinese_chars.uniq.join(', ')}"
        puts ""
        
        # 解析结果
        parser = OcrResultParser.new(ocr_result[:raw_text])
        parsed_data = parser.parse
        
        # 计算准确率
        valid_fields = parsed_data.select { |k, v| v && !v.to_s.empty? }.size
        total_fields = parsed_data.size
        accuracy = (valid_fields.to_f / total_fields * 100).round(2)
        
        puts "   ✅ 解析完成，准确率: #{accuracy}%"
        puts ""
        
        # 显示解析结果
        puts "     解析结果:"
        parsed_data.each do |key, value|
          status = value && !value.to_s.empty? ? "✅" : "❌"
          puts "     #{status} #{key}: #{value || '空'}"
        end
        
      else
        puts "   ❌ 系统未识别到中文字符"
        puts "     识别文本: #{ocr_result[:raw_text][0..100]}..."
      end
      
    else
      puts "   ❌ OCR识别失败: #{ocr_result[:error]}"
    end
    
    # 清理测试文件
    File.delete(system_test_path)
    
  else
    puts "   ❌ 系统测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ 系统OCR服务测试失败: #{e.message}"
end

puts ""

# 3. 修复效果总结
puts "3. 修复效果总结:"
puts ""

puts "   ✅ 已完成修复:"
puts "     - 重新安装Tesseract中文语言包"
puts "     - 清理冗余OCR服务"
puts "     - 验证英文面单识别功能"
puts ""

puts "   ⚠️ 待解决问题:"
puts "     - 中文识别能力需要进一步验证"
puts "     - API接口调用参数需要修复"
puts ""

puts "=== 中文OCR识别修复效果验证完成 ==="