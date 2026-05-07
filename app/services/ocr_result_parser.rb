# OCR结果解析服务 - 结构化提取关键字段
class OcrResultParser
  def initialize(raw_text)
    @raw_text = raw_text
    @lines = raw_text.split(/\n+/).map(&:strip).reject(&:empty?)
  end

  # 解析所有字段
  def parse
    {
      tracking_number: extract_tracking_number,
      recipient_name: extract_recipient_name,
      recipient_phone: extract_recipient_phone,
      recipient_province: extract_province,
      recipient_city: extract_city,
      recipient_district: extract_district,
      recipient_address: extract_recipient_address,
      sender_name: extract_sender_name,
      sender_phone: extract_sender_phone,
      courier_company: extract_courier_company,
      raw_text: @raw_text
    }
  end

  private

  # 提取运单号
  def extract_tracking_number
    # 常见运单号模式
    patterns = [
      /(?:运单号|单号|Tracking|Tracking.*?No)[：:\s]*([A-Z0-9]{10,20})/i,
      /\b(SF|ZT|YT|JD|EMS)[A-Z0-9]{8,18}\b/i,
      /\b([0-9]{12,18})\b/
    ]

    patterns.each do |pattern|
      match = @raw_text.match(pattern)
      return match[1] if match
    end

    # 改进的快递单号提取
    # 顺丰快递 SF1234567890 -> 提取SF1234567890
    courier_patterns = [
      /(?:顺丰|圆通|中通|韵达|申通|京东|EMS|邮政)[^\n]*\b(SF|YT|ZT|YD|ST|JD|EMS)[A-Z0-9]{8,18}\b/i,
      /\b(SF|ZT|YT|JD|EMS)[A-Z0-9]{8,18}\b/i,
      /\b([0-9]{12,18})\b/
    ]

    courier_patterns.each do |pattern|
      match = @raw_text.match(pattern)
      return match[1] if match
    end

    # 增强的运单号提取：查找包含快递公司前缀的完整运单号
    enhanced_patterns = [
      /(顺丰|圆通|中通|韵达|申通|京东|EMS|邮政)[^\n]*([A-Z0-9]{10,20})/i,
      /([A-Z]{2,4}[0-9]{8,16})/i,
      /([0-9]{12,18})/
    ]

    enhanced_patterns.each do |pattern|
      match = @raw_text.match(pattern)
      if match && match[2]
        return match[2]
      elsif match && match[1]
        return match[1]
      end
    end

    # 如果没有找到，寻找看起来像运单号的字符串
    @lines.each do |line|
      next if line.length < 10 || line.length > 20
      next unless line.match?(/^[A-Z0-9]+$/i)
      return line
    end

    nil
  end

  # 提取收件人姓名
  def extract_recipient_name
    # 收件人标签
    recipient_keywords = [ "收件人", "收货人", "收件", "To", "收" ]

    recipient_keywords.each do |keyword|
      @lines.each do |line|
        next unless line.include?(keyword)

        # 使用正则表达式提取关键词后的内容
        pattern = /#{keyword}[：:\s]*(.+)/
        match = line.match(pattern)
        next unless match

        content = match[1]&.strip
        next unless content

        # 清理非姓名内容
        name = content.split(/[，。、；;]/).first&.strip

        # 验证姓名格式（2-4个中文字符）
        if name && name.match?(/^[\u4e00-\u9fa5]{2,4}$/)
          return name
        end
      end
    end

    # 备用：直接查找姓名格式的文本
    @lines.each do |line|
      # 查找2-4个中文字符的姓名
      name_candidate = line.match(/[\u4e00-\u9fa5]{2,4}/)
      if name_candidate && !looks_like_address?(line) && !line.include?("快递") && !line.include?("地址")
        return name_candidate[0]
      end
    end

    nil
  end

  # 提取收件人电话
  def extract_recipient_phone
    # 中国手机号模式：1开头，11位数字
    phone_pattern = /1[3-9]\d{9}/

    # 先找收件人附近的电话
    recipient_keywords = [ "收件人", "收货人", "收件", "To" ]

    recipient_keywords.each do |keyword|
      @lines.each_cons(2) do |line1, line2|
        if line1.include?(keyword)
          match = (line1 + line2).match(phone_pattern)
          return match[0] if match
        end
      end
    end

    # 直接查找所有手机号
    matches = @raw_text.scan(phone_pattern)
    return matches.first if matches.any?

    nil
  end

  # 提取省份
  def extract_province
    provinces = [ "北京", "天津", "河北", "山西", "内蒙古", "辽宁", "吉林", "黑龙江",
                 "上海", "江苏", "浙江", "安徽", "福建", "江西", "山东", "河南",
                 "湖北", "湖南", "广东", "广西", "海南", "重庆", "四川", "贵州",
                 "云南", "西藏", "陕西", "甘肃", "青海", "宁夏", "新疆",
                 "香港", "澳门", "台湾" ]

    provinces.each do |province|
      return province if @raw_text.include?(province)
    end

    nil
  end

  # 提取城市
  def extract_city
    city_suffixes = [ "市", "市辖区" ]

    @lines.each do |line|
      city_suffixes.each do |suffix|
        if line.include?(suffix)
          # 使用正则提取城市名称
          pattern = /([\u4e00-\u9fa5]+#{suffix})/
          match = line.match(pattern)
          return match[1] if match
        end
      end
    end

    nil
  end

  # 提取区县
  def extract_district
    district_suffixes = [ "区", "县", "旗", "特区" ]

    @lines.each do |line|
      district_suffixes.each do |suffix|
        if line.include?(suffix) && !line.include?("市")
          district = line.split(suffix).first + suffix
          return district if district.length >= 2
        end
      end
    end

    nil
  end

  # 提取详细地址
  def extract_recipient_address
    # 地址关键词
    address_keywords = [ "地址", "Address", "收货地址", "收件地址" ]

    address_keywords.each do |keyword|
      @lines.each do |line|
        next unless line.include?(keyword)

        # 使用正则提取地址内容
        pattern = /#{keyword}[：:\s]*(.+)/
        match = line.match(pattern)
        next unless match

        content = match[1]&.strip

        # 验证地址格式（包含地址特征）
        if content && content.length >= 5 && looks_like_address?(content)
          return content
        end
      end
    end

    # 查找包含地址特征的行
    @lines.each do |line|
      # 跳过包含快递、收件人等关键词的行
      next if line.include?("快递") || line.include?("收件人") || line.include?("手机")

      if looks_like_address?(line) && line.length >= 5
        return line
      end
    end

    nil
  end

  # 提取寄件人姓名
  def extract_sender_name
    sender_keywords = [ "寄件人", "发件人", "寄件", "From", "发" ]

    sender_keywords.each do |keyword|
      @lines.each do |line|
        next unless line.include?(keyword)

        content = line.split(keyword).last&.strip
        next unless content

        name = content.split(/[：:\s，。、；;]/).first
        return name if name && name.length >= 2 && name.length <= 4
      end
    end

    nil
  end

  # 提取寄件人电话
  def extract_sender_phone
    phone_pattern = /1[3-9]\d{9}/
    sender_keywords = [ "寄件人", "发件人", "寄件", "From" ]

    all_phones = @raw_text.scan(phone_pattern)
    return nil if all_phones.size < 2

    # 如果有多个电话，找寄件人附近的
    sender_keywords.each do |keyword|
      @lines.each_cons(2) do |line1, line2|
        if line1.include?(keyword)
          line1.scan(phone_pattern).each do |phone|
            return phone if all_phones.index(phone) != 0
          end
          line2.scan(phone_pattern).each do |phone|
            return phone if all_phones.index(phone) != 0
          end
        end
      end
    end

    # 返回第二个电话（假设第一个是收件人）
    all_phones[1]
  end

  # 提取快递公司
  def extract_courier_company
    companies = {
      "顺丰" => "顺丰速运",
      "SF" => "顺丰速运",
      "圆通" => "圆通速递",
      "YT" => "圆通速递",
      "中通" => "中通快递",
      "ZT" => "中通快递",
      "韵达" => "韵达快递",
      "YD" => "韵达快递",
      "申通" => "申通快递",
      "ST" => "申通快递",
      "京东" => "京东物流",
      "JD" => "京东物流",
      "EMS" => "EMS",
      "邮政" => "EMS",
      "德邦" => "德邦快递",
      "极兔" => "极兔速递",
      "百世" => "百世快递"
    }

    companies.each do |keyword, name|
      return name if @raw_text.include?(keyword)
    end

    nil
  end

  # 判断是否像地址
  def looks_like_address?(text)
    address_indicators = [ "路", "街", "巷", "号", "栋", "单元", "室",
                         "村", "镇", "乡", "园", "区", "广场", "大厦",
                         "楼", "房", "铺", "店" ]

    address_indicators.any? { |indicator| text.include?(indicator) }
  end
end
