# 演示用OCR服务 - 当Tesseract不可用时使用
class DemoOcrService
  def initialize(image_path)
    @image_path = image_path
  end

  # 模拟OCR识别（返回模拟数据）
  def recognize
    start_time = Time.now

    Rails.logger.info "使用演示OCR服务进行识别..."

    # 模拟处理延迟
    sleep(1.5)

    # 生成随机但真实的模拟数据
    raw_text = generate_mock_text
    processing_time = Time.now - start_time

    {
      success: true,
      raw_text: raw_text,
      processing_time: processing_time,
      image_info: {
        width: 1200,
        height: 800,
        format: 'PNG'
      },
      is_demo: true  # 标记为演示数据
    }
  rescue => e
    {
      success: false,
      error: "演示OCR失败: #{e.message}",
      error_backtrace: e.backtrace
    }
  end

  private

  # 生成模拟的OCR文本
  def generate_mock_text
    companies = ['顺丰速运', '圆通速递', '中通快递', '韵达快递', '申通快递', '京东物流']
    provinces = ['北京市', '上海市', '广东省', '浙江省', '江苏省', '四川省', '湖北省', '湖南省']
    cities = ['广州市', '深圳市', '杭州市', '南京市', '成都市', '武汉市', '长沙市']
    districts = ['福田区', '南山区', '浦东新区', '海淀区', '西湖区', '江干区']
    streets = ['科技园路', '中关村大街', '人民路', '建设路', '解放路', '和平路']

    company = companies.sample
    province = provinces.sample
    city = cities.sample
    district = districts.sample
    street = streets.sample

    tracking_number = generate_tracking_number(company)
    phone = "1#{rand(3..9)}#{rand(100000000..999999999)}"
    sender_phone = "1#{rand(3..9)}#{rand(100000000..999999999)}"
    recipient_name = ['张三', '李四', '王五', '赵六', '钱七'].sample
    sender_name = ['孙八', '周九', '吴十', '郑十一', '王十二'].sample

    <<~TEXT
      顺丰速运 SF Express

      运单号: #{tracking_number}

      收件人信息:
      姓名: #{recipient_name}
      电话: #{phone}
      地址: #{province}#{city}#{district}#{street}128号
      小区: #{['阳光花园', '碧桂园', '万科城', '保利花园', '中海锦城'].sample}#{rand(1..20)}栋#{rand(101..2999)}室

      寄件人信息:
      姓名: #{sender_name}
      电话: #{sender_phone}
      地址: #{['广东省深圳市', '浙江省杭州市', '北京市海淀区', '上海市浦东新区'].sample}#{['科技路', '创业路', '软件园'].sample}#{rand(1..100)}号

      物品信息:
      类别: 包裹
      重量: #{rand(1..20)}.#{rand(0..9)}kg
      付款方式: 到付

      备注: 请当面签收
    TEXT
  end

  # 生成模拟运单号
  def generate_tracking_number(company)
    case company
    when '顺丰速运'
      "SF#{rand(100000000000..999999999999)}"
    when '圆通速递'
      "YT#{rand(1000000000..9999999999)}"
    when '中通快递'
      "ZT#{rand(1000000000..9999999999)}"
    when '韵达快递'
      "YD#{rand(1000000000..9999999999)}"
    when '京东物流'
      "JD#{rand(10000000000..99999999999)}"
    else
      "EX#{rand(1000000000..9999999999)}"
    end
  end
end