class CustomerChatbotService
  def initialize
    @deepseek_service = DeepseekApiService.new(ENV["DEEPSEEK_API_KEY"])
    @conversation_history = []
  end

  # 处理用户消息
  def process_message(user_message, user_context = {})
    begin
      # 使用DeepSeek API进行智能回复
      result = @deepseek_service.intelligent_customer_service(user_message, @conversation_history)

      if result[:success]
        # 更新对话历史
        update_conversation_history(user_message, result[:data][:content])

        {
          success: true,
          data: {
            response: result[:data][:content],
            intent: extract_intent_from_response(result[:data][:content]),
            suggested_actions: generate_suggested_actions(result[:data][:content]),
            confidence: 0.95,
            api_usage: result[:data][:usage]
          }
        }
      else
        # 如果API调用失败，回退到规则引擎
        fallback_response = generate_fallback_response(user_message)
        {
          success: true,
          data: {
            response: fallback_response[:message],
            intent: :fallback,
            suggested_actions: fallback_response[:suggested_actions],
            confidence: 0.7
          }
        }
      end
    rescue => e
      {
        success: false,
        error: "聊天机器人处理失败: #{e.message}"
      }
    end
  end

  # 更新对话历史
  def update_conversation_history(user_message, bot_response)
    # 保持最近10轮对话
    @conversation_history << { role: "user", content: user_message }
    @conversation_history << { role: "assistant", content: bot_response }

    if @conversation_history.size > 20  # 最多保留10轮对话
      @conversation_history = @conversation_history.last(20)
    end
  end

  # 分析用户意图
  def analyze_intent(message)
    message = message.downcase.strip

    # 包裹查询相关意图
    if message.include?("查询") || message.include?("查包裹") || message.include?("快递") || message.include?("快递单号")
      :package_query
    elsif message.include?("取件") || message.include?("取包裹") || message.include?("领取")
      :pickup_info
    elsif message.include?("地址") || message.include?("位置") || message.include?("在哪里")
      :location_info
    elsif message.include?("时间") || message.include?("营业") || message.include?("几点")
      :business_hours
    elsif message.include?("费用") || message.include?("收费") || message.include?("多少钱")
      :pricing_info
    elsif message.include?("投诉") || message.include?("问题") || message.include?("异常")
      :complaint
    elsif message.include?("帮助") || message.include?("怎么") || message.include?("如何")
      :help
    elsif message.include?("谢谢") || message.include?("感谢") || message.include?("辛苦了")
      :thanks
    elsif message.include?("你好") || message.include?("您好") || message.include?("hello") || message.include?("hi")
      :greeting
    else
      :general_inquiry
    end
  end

  # 从AI回复中提取意图
  def extract_intent_from_response(response)
    response = response.downcase

    if response.include?("查询") || response.include?("包裹") || response.include?("快递")
      :package_query
    elsif response.include?("取件") || response.include?("取包裹")
      :pickup_info
    elsif response.include?("地址") || response.include?("位置")
      :location_info
    elsif response.include?("时间") || response.include?("营业")
      :business_hours
    elsif response.include?("费用") || response.include?("收费")
      :pricing_info
    elsif response.include?("投诉") || response.include?("问题")
      :complaint
    else
      :general_inquiry
    end
  end

  # 生成建议操作
  def generate_suggested_actions(response)
    actions = []
    response = response.downcase

    if response.include?("查询") || response.include?("包裹")
      actions << "查看包裹详情"
      actions << "联系客服"
    elsif response.include?("取件")
      actions << "查看取件流程"
      actions << "联系取件点"
    elsif response.include?("地址") || response.include?("位置")
      actions << "查看地图位置"
      actions << "导航到驿站"
    else
      actions << "继续咨询"
      actions << "联系人工客服"
    end

    actions
  end

  # 生成回退响应（当API失败时使用）
  def generate_fallback_response(user_message)
    # 简单的规则引擎作为回退
    message = user_message.downcase

    if message.include?("查询") || message.include?("包裹")
      {
        message: "我可以帮您查询包裹状态。请提供运单号或手机号码。",
        suggested_actions: [ "输入运单号", "输入手机号", "联系人工客服" ]
      }
    elsif message.include?("取件")
      {
        message: "取件流程：1. 凭取件码到驿站 2. 出示身份证明 3. 签字确认。营业时间：8:00-20:00",
        suggested_actions: [ "查看取件流程", "联系取件点" ]
      }
    elsif message.include?("你好") || message.include?("您好")
      {
        message: "您好！我是快递驿站AI助手，很高兴为您服务。请问有什么可以帮您？",
        suggested_actions: [ "查询包裹", "取件咨询", "营业信息" ]
      }
    else
      {
        message: "我理解您的问题了。为了更好地帮助您，请提供更多详细信息，或者联系人工客服获得更专业的帮助。",
        suggested_actions: [ "重新描述问题", "联系人工客服" ]
      }
    end
  end

  # 生成回复
  def generate_response(intent, message, user_context)
    case intent
    when :package_query
      handle_package_query(message, user_context)
    when :pickup_info
      handle_pickup_info(message, user_context)
    when :location_info
      handle_location_info
    when :business_hours
      handle_business_hours
    when :pricing_info
      handle_pricing_info
    when :complaint
      handle_complaint(message)
    when :help
      handle_help
    when :thanks
      handle_thanks
    when :greeting
      handle_greeting
    else
      handle_general_inquiry(message)
    end
  end

  # 处理包裹查询
  def handle_package_query(message, user_context)
    # 提取运单号或手机号
    tracking_number = extract_tracking_number(message)
    phone_number = extract_phone_number(message)

    if tracking_number
      package = Package.find_by(tracking_number: tracking_number)
      if package
        {
          message: generate_package_status_message(package),
          suggested_actions: [ "查看详细包裹信息", "联系客服" ],
          confidence: 0.95
        }
      else
        {
          message: "抱歉，没有找到运单号为 #{tracking_number} 的包裹。请检查运单号是否正确。",
          suggested_actions: [ "重新输入运单号", "联系人工客服" ],
          confidence: 0.9
        }
      end
    elsif phone_number
      packages = Package.where(recipient_phone: phone_number).where(status: [ :pending, :stored ])
      if packages.any?
        package_list = packages.map { |p| "#{p.tracking_number} - #{p.status_name}" }.join("\n")
        {
          message: "找到以下待取件包裹：\n#{package_list}\n\n请输入运单号查询详细信息。",
          suggested_actions: packages.map { |p| "查询 #{p.tracking_number}" } + [ "联系客服" ],
          confidence: 0.9
        }
      else
        {
          message: "抱歉，没有找到手机号 #{phone_number} 的待取件包裹。",
          suggested_actions: [ "重新输入手机号", "联系人工客服" ],
          confidence: 0.9
        }
      end
    else
      {
        message: "请提供运单号或手机号，我可以帮您查询包裹状态。",
        suggested_actions: [ "如何查询包裹", "联系客服" ],
        confidence: 0.8
      }
    end
  end

  # 处理取件信息
  def handle_pickup_info(message, user_context)
    {
      message: "取件流程：\n1. 提供运单号或取件码\n2. 工作人员核对信息\n3. 签字确认取件\n4. 完成取件\n\n营业时间：8:00-20:00\n取件地点：驿站前台",
      suggested_actions: [ "查询我的包裹", "查看营业时间", "联系客服" ],
      confidence: 0.95
    }
  end

  # 处理位置信息
  def handle_location_info
    {
      message: "我们的驿站位于：\n📍 北京市朝阳区某某街道123号\n🚇 地铁10号线某某站A出口步行5分钟\n🚌 公交某某路某某站下车即到\n\n如需导航，可以使用地图应用搜索'某某快递驿站'。",
      suggested_actions: [ "查看营业时间", "联系客服", "路线导航" ],
      confidence: 0.95
    }
  end

  # 处理营业时间
  def handle_business_hours
    {
      message: "营业时间安排：\n🕘 周一至周日：8:00 - 20:00\n📦 包裹收发：全天营业\n💼 客服咨询：8:00 - 18:00\n\n节假日正常营业，如有调整会提前通知。",
      suggested_actions: [ "查看位置信息", "联系客服", "包裹查询" ],
      confidence: 0.95
    }
  end

  # 处理费用信息
  def handle_pricing_info
    {
      message: "收费标准：\n📦 普通包裹：免费存储3天，超过后每天1元\n📦 大件包裹：免费存储1天，超过后每天3元\n📦 文件类：免费存储7天\n💰 代收货款：手续费2%（最低2元）\n\n具体费用以实际包裹为准。",
      suggested_actions: [ "包裹查询", "联系客服", "查看营业时间" ],
      confidence: 0.9
    }
  end

  # 处理投诉
  def handle_complaint(message)
    {
      message: "非常抱歉给您带来不便。请描述具体问题，我会尽力帮助您解决。\n\n您也可以直接联系人工客服：\n📞 客服电话：400-123-4567\n💬 在线客服：8:00-18:00",
      suggested_actions: [ "联系人工客服", "包裹查询", "查看营业时间" ],
      confidence: 0.85
    }
  end

  # 处理帮助
  def handle_help
    {
      message: "我可以帮您：\n🔍 查询包裹状态\n📍 查看驿站位置\n🕘 了解营业时间\n💰 查询收费标准\n📦 获取取件帮助\n\n请告诉我您需要什么帮助？",
      suggested_actions: [ "包裹查询", "位置信息", "营业时间", "收费标准" ],
      confidence: 0.95
    }
  end

  # 处理感谢
  def handle_thanks
    {
      message: "不客气！很高兴能帮助您。如果还有其他问题，随时可以问我哦！😊",
      suggested_actions: [ "包裹查询", "查看营业时间", "联系客服" ],
      confidence: 0.95
    }
  end

  # 处理问候
  def handle_greeting
    {
      message: "您好！我是快递驿站智能助手，很高兴为您服务！\n我可以帮您查询包裹、了解驿站信息等。请问有什么可以帮您的？",
      suggested_actions: [ "包裹查询", "位置信息", "营业时间", "帮助" ],
      confidence: 0.95
    }
  end

  # 处理一般咨询
  def handle_general_inquiry(message)
    {
      message: "我主要可以帮助您：\n• 查询包裹状态\n• 了解驿站信息\n• 获取取件帮助\n\n请告诉我您具体想了解什么？或者输入'帮助'查看详细功能。",
      suggested_actions: [ "帮助", "包裹查询", "联系客服" ],
      confidence: 0.8
    }
  end

  # 生成包裹状态消息
  def generate_package_status_message(package)
    status_mapping = {
      pending: "待入库",
      stored: "已入库待取件",
      picked_up: "已取件",
      exception: "异常状态"
    }

    "包裹状态信息：\n📦 运单号：#{package.tracking_number}\n👤 收件人：#{package.recipient_name}\n📱 手机号：#{package.recipient_phone}\n🏷️ 状态：#{status_mapping[package.status.to_sym]}\n📍 位置：#{package.storage_location || '待分配'}\n📅 入库时间：#{package.created_at.strftime('%Y-%m-%d %H:%M')}"
  end

  # 提取运单号
  def extract_tracking_number(message)
    patterns = [
      /SF\d{10,12}/,     # 顺丰
      /YT\d{10,12}/,     # 圆通
      /ZT\d{10,12}/,     # 中通
      /YD\d{10,12}/,     # 韵达
      /STO\d{10,12}/,    # 申通
      /JD\d{10,12}/,     # 京东
      /\d{12,14}/        # 通用数字格式
    ]

    patterns.each do |pattern|
      match = message.match(pattern)
      return match[0] if match
    end

    nil
  end

  # 提取手机号
  def extract_phone_number(message)
    phone_pattern = /1[3-9]\d{9}/
    match = message.match(phone_pattern)
    match ? match[0] : nil
  end

  # 学习用户偏好（简单的上下文记忆）
  def learn_user_preferences(user_id, interaction_data)
    # 这里可以实现用户偏好的学习和记忆
    # 例如：记住用户常用的查询方式、偏好语言等
  end
end
