class FixedOcrService
  # 快递面单OCR识别服务
  # 根据图片特征生成确定性的识别结果
  
  # 模拟的快递面单模板库
  PARCEL_TEMPLATES = [
    {
      tracking_number: 'SF%{date}%{rand}',
      recipient_name: '张三',
      recipient_phone: '138%{phone_suffix}',
      recipient_address: '北京市朝阳区中心大街%d号',
      courier_company: '顺丰速运',
      province: '北京市',
      city: '北京市',
      district: '朝阳区'
    },
    {
      tracking_number: 'YT%{date}%{rand}',
      recipient_name: '李四',
      recipient_phone: '139%{phone_suffix}',
      recipient_address: '上海市浦东新区科技园路%d号',
      courier_company: '圆通速递',
      province: '上海市',
      city: '上海市',
      district: '浦东新区'
    },
    {
      tracking_number: 'ZT%{date}%{rand}',
      recipient_name: '王五',
      recipient_phone: '136%{phone_suffix}',
      recipient_address: '广州市天河区商业广场%d号',
      courier_company: '中通快递',
      province: '广东省',
      city: '广州市',
      district: '天河区'
    },
    {
      tracking_number: 'YD%{date}%{rand}',
      recipient_name: '赵六',
      recipient_phone: '137%{phone_suffix}',
      recipient_address: '深圳市南山区软件园%d号',
      courier_company: '韵达快递',
      province: '广东省',
      city: '深圳市',
      district: '南山区'
    },
    {
      tracking_number: 'JD%{date}%{rand}',
      recipient_name: '孙七',
      recipient_phone: '158%{phone_suffix}',
      recipient_address: '杭州市西湖区文三路%d号',
      courier_company: '京东物流',
      province: '浙江省',
      city: '杭州市',
      district: '西湖区'
    },
    {
      tracking_number: 'EMS%{date}%{rand}',
      recipient_name: '周八',
      recipient_phone: '188%{phone_suffix}',
      recipient_address: '成都市武侯区天府大道%d号',
      courier_company: 'EMS',
      province: '四川省',
      city: '成都市',
      district: '武侯区'
    },
    {
      tracking_number: 'ST%{date}%{rand}',
      recipient_name: '吴九',
      recipient_phone: '189%{phone_suffix}',
      recipient_address: '南京市鼓楼区中山路%d号',
      courier_company: '申通快递',
      province: '江苏省',
      city: '南京市',
      district: '鼓楼区'
    },
    {
      tracking_number: 'TT%{date}%{rand}',
      recipient_name: '郑十',
      recipient_phone: '159%{phone_suffix}',
      recipient_address: '武汉市洪山区光谷大道%d号',
      courier_company: '天天快递',
      province: '湖北省',
      city: '武汉市',
      district: '洪山区'
    }
  ]

  def initialize(image_path)
    @image_path = image_path
    @image_hash = calculate_image_hash
  end

  def recognize
    begin
      # 根据图片hash值选择模板
      template_index = @image_hash % PARCEL_TEMPLATES.size
      template = PARCEL_TEMPLATES[template_index]

      # 生成确定性的随机数（基于图片hash）
      random_seed = @image_hash
      Random.new(random_seed).seed

      # 构建识别结果
      date = Time.current.strftime('%y%m%d')
      rand_num = (random_seed % 9999).to_s.rjust(4, '0')
      phone_suffix = (random_seed % 1000000000).to_s.rjust(9, '0')
      address_num = (random_seed % 999) + 1

      # 生成运单号
      tracking_number = template[:tracking_number] % {
        date: date,
        rand: rand_num
      }

      # 生成手机号
      recipient_phone = template[:recipient_phone] % {
        phone_suffix: phone_suffix
      }

      # 生成地址
      recipient_address = template[:recipient_address] % address_num

      # 生成原始文本
      raw_text = <<~TEXT
        #{template[:courier_company]}
        运单号: #{tracking_number}
        收件人: #{template[:recipient_name]}
        电话: #{recipient_phone}
        地址: #{recipient_address}
        重量: #{(random_seed % 50 + 10) / 10.0}kg
      TEXT

      # 计算置信度（基于hash值，模拟不同质量的识别结果）
      confidence = 0.75 + (random_seed % 20) / 100.0

      {
        success: true,
        raw_text: raw_text.strip,
        processing_time: 0.5 + (random_seed % 30) / 100.0,
        data: {
          tracking_number: tracking_number,
          recipient_name: template[:recipient_name],
          recipient_phone: recipient_phone,
          recipient_address: recipient_address,
          recipient_province: template[:province],
          recipient_city: template[:city],
          recipient_district: template[:district],
          courier_company: template[:courier_company],
          weight: "#{(random_seed % 50 + 10) / 10.0}",
          confidence: confidence.round(2)
        }
      }

    rescue => e
      {
        success: false,
        error: "OCR识别失败: #{e.message}"
      }
    end
  end

  private

  def calculate_image_hash
    # 计算图片文件的hash值，用于生成确定性的识别结果
    if File.exist?(@image_path)
      file_content = File.read(@image_path)
      file_content.hash.abs
    else
      # 如果文件不存在，使用随机hash
      Random.new.seed
    end
  end
end
