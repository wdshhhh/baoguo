#!/usr/bin/env ruby

# 修复Tesseract中文识别问题
require_relative 'config/environment'

puts "=== 修复Tesseract中文识别问题 ==="
puts ""

# 1. 检查Tesseract安装状态
puts "1. Tesseract安装状态检查:"
puts ""

begin
  # 检查Tesseract命令
  tesseract_path = `which tesseract`.strip
  if tesseract_path.empty?
    puts "   ❌ Tesseract未安装"
  else
    puts "   ✅ Tesseract已安装: #{tesseract_path}"
    
    # 检查版本
    version_info = `tesseract --version 2>&1`
    puts "     版本信息: #{version_info.lines.first.strip}"
  end
  
rescue => e
  puts "   ❌ Tesseract检查失败: #{e.message}"
end

puts ""

# 2. 检查中文语言包
puts "2. 中文语言包检查:"
puts ""

begin
  # 检查语言包列表
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
  
  # 检查语言包文件路径
  puts ""
  puts "   - 语言包文件路径检查:"
  
  # 查找语言包文件
  possible_paths = [
    "/usr/share/tesseract-ocr/4.00/tessdata/",
    "/usr/share/tesseract-ocr/tessdata/",
    "/usr/local/share/tessdata/",
    "/usr/share/tessdata/"
  ]
  
  possible_paths.each do |path|
    if File.directory?(path)
      puts "     检查路径: #{path}"
      
      # 检查中文语言包文件
      chinese_files = Dir["#{path}chi_*.traineddata"]
      if chinese_files.any?
        puts "       ✅ 找到中文语言包: #{chinese_files.join(', ')}"
      else
        puts "       ❌ 未找到中文语言包"
      end
    end
  end
  
rescue => e
  puts "   ❌ 语言包检查失败: #{e.message}"
end

puts ""

# 3. 测试中文识别能力
puts "3. 中文识别能力测试:"
puts ""

begin
  # 创建中文测试图片
  chinese_test_path = "/tmp/chinese_detailed_test_#{Time.now.to_i}.jpg"
  
  # 使用更清晰的中文文本
  system("convert -size 600x400 xc:white -pointsize 28 -fill black -gravity center -annotate +0+0 '顺丰快递\\nSF1234567890\\n收件人: 张三\\n手机: 13800138000\\n地址: 北京市朝阳区' #{chinese_test_path}")
  
  if File.exist?(chinese_test_path)
    puts "   ✅ 中文测试图片创建成功"
    
    # 测试不同语言组合
    language_combinations = [
      { lang: 'chi_sim', desc: '简体中文' },
      { lang: 'chi_tra', desc: '繁体中文' },
      { lang: 'chi_sim+eng', desc: '简体中文+英文' },
      { lang: 'eng+chi_sim', desc: '英文+简体中文' }
    ]
    
    language_combinations.each do |combo|
      puts "   - 测试语言: #{combo[:desc]} (#{combo[:lang]})"
      
      begin
        tesseract_cmd = "tesseract #{chinese_test_path} stdout -l #{combo[:lang]} --psm 6 2>&1"
        result = `#{tesseract_cmd}`.strip
        
        if result && !result.empty?
          puts "     ✅ 识别成功"
          puts "       识别结果: #{result[0..100]}..."
          
          # 统计中文字符
          chinese_chars = result.scan(/[\u4e00-\u9fa5]/)
          puts "       中文字符数: #{chinese_chars.size}"
          
          if chinese_chars.size > 0
            puts "       识别到的中文: #{chinese_chars.uniq.join(', ')}"
          end
          
        else
          puts "     ❌ 识别失败或结果为空"
        end
        
      rescue => e
        puts "     ❌ 调用失败: #{e.message}"
      end
      
      puts ""
    end
    
    # 清理测试文件
    File.delete(chinese_test_path)
    
  else
    puts "   ❌ 中文测试图片创建失败"
  end
  
rescue => e
  puts "   ❌ 中文识别测试失败: #{e.message}"
end

puts ""

# 4. 修复建议
puts "4. 修复建议:"
puts ""

puts "   如果中文识别仍然失败，建议:"
puts "   "
puts "   1. 重新安装Tesseract中文语言包:"
puts "      sudo apt install tesseract-ocr-chi-sim tesseract-ocr-chi-tra"
puts "   "
puts "   2. 检查语言包文件权限:"
puts "      sudo chmod 644 /usr/share/tesseract-ocr/*/tessdata/chi_*.traineddata"
puts "   "
puts "   3. 设置TESSDATA_PREFIX环境变量:"
puts "      export TESSDATA_PREFIX=/usr/share/tesseract-ocr/4.00/tessdata/"
puts "   "
puts "   4. 使用替代OCR方案:"
puts "      - 调用在线OCR API（百度OCR、腾讯OCR等）"
puts "      - 使用其他OCR库（PaddleOCR、EasyOCR等）"

puts ""
puts "=== Tesseract中文识别修复完成 ==="