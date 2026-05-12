#!/usr/bin/env ruby
# 快递面单测试图片生成器
# 用于测试OCR识别功能

require 'mini_magick'
require 'tmpdir'
require 'shellwords'

class ParcelTestGenerator
  COURIERS = [
    { name: '顺丰速运', prefix: 'SF', color: '#DC2626' },
    { name: '中通快递', prefix: 'ZT', color: '#16A34A' },
    { name: '圆通速递', prefix: 'YT', color: '#F59E0B' },
    { name: '申通快递', prefix: 'ST', color: '#8B5CF6' },
    { name: '韵达快递', prefix: 'YD', color: '#EC4899' },
    { name: '京东物流', prefix: 'JD', color: '#3B82F6' }
  ]

  NAMES = [ '张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十' ]
  PROVINCES = [ '北京市', '上海市', '广东省', '浙江省', '江苏省' ]
  CITIES = [ '朝阳区', '浦东新区', '天河区', '西湖区', '玄武区' ]
  STREETS = [ '科技园路', '中关村大街', '人民路', '建设路', '解放路' ]
  COMMUNITIES = [ '阳光花园', '碧桂园', '万科城', '保利花园', '中海锦城' ]

  def initialize(output_dir = 'test_parcels')
    @output_dir = output_dir
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
  end

  def generate(count = 10)
    puts "🚀 正在生成 #{count} 张测试面单..."

    count.times do |i|
      generate_single(i + 1)
    end

    puts "✅ 测试面单已生成到 #{@output_dir}/ 目录"
  end

  def generate_single(index)
    courier = COURIERS.sample
    name = NAMES.sample
    phone = "1#{[ 3, 5, 7, 8, 9 ].sample}#{rand(100000000..999999999)}"
    province = PROVINCES.sample
    city = CITIES.sample
    street = STREETS.sample
    community = COMMUNITIES.sample
    tracking_number = "#{courier[:prefix]}#{rand(1000000000..9999999999)}"
    building = rand(1..20)
    room = "#{rand(101..1501)}室"
    full_address = "#{province}#{city}#{street}#{community}#{building}栋#{room}"

    filename = "#{@output_dir}/parcel_#{courier[:prefix]}#{index}.png"

    # 使用convert命令生成面单图片
    draw_commands = []
    draw_commands << "fill none stroke #{courier[:color]} stroke-width 2 rectangle 5,5 495,345"
    draw_commands << "fill none stroke #e5e7eb stroke-width 1 rectangle 10,10 490,340"
    draw_commands << "fill #{courier[:color]} text 20,50 '#{courier[:name]}'"
    draw_commands << "fill '#1f2937' text 20,90 '运单号: #{tracking_number}'"
    draw_commands << "fill '#e5e7eb' stroke '#e5e7eb' line 20,100 480,100"
    draw_commands << "fill '#6b7280' text 20,130 '收件人信息'"
    draw_commands << "fill '#1f2937' text 20,160 '姓名: #{name}'"
    draw_commands << "fill '#1f2937' text 20,190 '电话: #{phone}'"
    draw_commands << "fill '#1f2937' text 20,220 '地址: #{full_address[0..25]}'"
    draw_commands << "fill '#4b5563' text 20,260 '寄件人: #{NAMES.sample}'"

    draw_str = draw_commands.map { |c| Shellwords.escape(c) }.join(' ')

    command = "convert -size 500x350 xc:white -font Arial -pointsize 16 -draw \"#{draw_commands.join(' ')}\" #{Shellwords.escape(filename)}"
    system(command)

    puts "📦 生成: #{filename}"

    {
      filename: filename,
      tracking_number: tracking_number,
      name: name,
      phone: phone,
      company: courier[:name],
      address: full_address
    }
  end

  def verify_ocr
    require_relative 'app/services/ocr_engine'
    require_relative 'app/services/ocr_post_processor'

    puts "\n🔍 正在验证OCR识别效果..."

    Dir.glob("#{@output_dir}/*.png").each do |file|
      next unless File.file?(file)

      puts "\n📄 文件: #{File.basename(file)}"

      begin
        result = OcrEngine.recognize(file, lang: 'chi_sim+eng')

        if result[:success]
          post_result = OcrPostProcessor.process(result[:result])
          data = post_result[:result]

          puts "   原始文本: #{result[:text].strip[0..80]}..."
          puts "   运单号: #{data[:tracking_number]}"
          puts "   姓名: #{data[:recipient_name]}"
          puts "   电话: #{data[:recipient_phone]}"
          puts "   快递公司: #{data[:courier_company]}"
          puts "   地址: #{data[:address]}"
          puts "   置信度: #{result[:confidence][:average].round(1)}%"
          puts "   质量等级: #{post_result[:result][:quality][:level]}"
        else
          puts "   ❌ 识别失败: #{result[:error]}"
        end
      rescue => e
        puts "   ❌ 识别异常: #{e.message}"
      end
    end
  end
end

if __FILE__ == $0
  generator = ParcelTestGenerator.new('test_parcels')

  count = ARGV[0] ? ARGV[0].to_i : 5

  generator.generate(count)

  generator.verify_ocr
end
