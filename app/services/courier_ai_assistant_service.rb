class CourierAiAssistantService
  # 知识库内容
  KNOWLEDGE_BASE = {
    business_hours: {
      title: "营业时间",
      content: "周一至周日：8:00 - 20:00\n节假日正常营业，春节期间营业时间调整请关注公告"
    },
    pricing: {
      title: "收费标准",
      content: "普通包裹：3元/件\n大件包裹（超过5kg或尺寸超标）：5元/件\n文件类：2元/件\n存储超过3天：加收1元/天"
    },
    pickup_process: {
      title: "取件流程",
      content: "1. 凭取件码到驿站\n2. 出示身份证明（身份证/学生证）\n3. 签字确认取件\n4. 领取包裹"
    },
    contact: {
      title: "联系方式",
      content: "驿站电话：400-888-8888\n地址：XX市XX区XX街道XX号\n微信公众号：菜鸟驿站XX店"
    },
    storage_rules: {
      title: "存放规则",
      content: "普通包裹免费存放3天\nVIP用户免费存放7天\n超过免费期每天收取1元保管费\n超过15天未取件将退回"
    },
    services: {
      title: "服务项目",
      content: "✅ 包裹代收代存\n✅ 快递代寄\n✅ 包裹打包\n✅ 冷链存储\n✅ 大件暂存"
    }
  }.freeze

  # 快捷问题
  QUICK_QUESTIONS = [
    { id: "business_hours", label: "营业时间", icon: "🕐" },
    { id: "pricing", label: "收费标准", icon: "💰" },
    { id: "pickup_process", label: "取件流程", icon: "📦" },
    { id: "contact", label: "联系方式", icon: "📞" },
    { id: "storage_rules", label: "存放规则", icon: "📋" },
    { id: "services", label: "服务项目", icon: "✨" }
  ].freeze

  def initialize
    @conversation_history = []
  end

  # 处理用户消息
  def process_message(user_message, conversation_history = [], current_user = nil)
    @conversation_history = conversation_history.dup

    # 添加当前用户消息到历史
    @conversation_history << { role: "user", content: user_message }

    # 保留最近10条对话
    @conversation_history = @conversation_history.last(10)

    # 1. 先尝试关键词匹配（问候语等）
    keyword_result = try_keyword_match(user_message)
    return keyword_result if keyword_result

    # 2. 尝试知识库匹配
    knowledge_result = try_knowledge_base_match(user_message)
    return knowledge_result if knowledge_result

    # 3. 尝试包裹查询
    package_result = try_package_query(user_message)
    return package_result if package_result

    # 4. 默认回复
    default_response
  end

  # 获取快捷问题列表
  def get_quick_questions
    {
      success: true,
      data: QUICK_QUESTIONS
    }
  end

  # 生成运营简报
  def generate_daily_report(package_stats = {})
    today = Date.today
    yesterday = today - 1

    # 默认统计数据
    stats = {
      today_packages: package_stats[:today_packages] || 156,
      delivered: package_stats[:delivered] || 132,
      pending: package_stats[:pending] || 24,
      exceptions: package_stats[:exceptions] || 5,
      avg_processing_time: package_stats[:avg_processing_time] || "3分钟",
      peak_hour: package_stats[:peak_hour] || "14:00-16:00"
    }

    pickup_rate = stats[:delivered].to_f / stats[:today_packages] * 100
    exception_rate = stats[:exceptions].to_f / stats[:today_packages] * 100

    report = <<~REPORT
      📈 **#{today.strftime('%Y年%m月%d日')} 运营简报**

      📦 **业务数据：**
      - 今日入库：#{stats[:today_packages]} 件
      - 已取件：#{stats[:delivered]} 件
      - 待取件：#{stats[:pending]} 件
      - 异常包裹：#{stats[:exceptions]} 件

      📊 **运营指标：**
      - 取件率：#{pickup_rate.round(1)}%
      - 异常率：#{exception_rate.round(1)}%
      - 平均处理时长：#{stats[:avg_processing_time]}/件
      - 高峰时段：#{stats[:peak_hour]}

      💡 **运营建议：**
      #{generate_suggestions(stats)}

      🎯 **明日计划：**
      - 预计包裹量与今日持平，请提前做好准备
      - 重点关注待取件的通知提醒工作
      - 继续保持异常包裹的及时处理
    REPORT

    {
      success: true,
      data: {
        report: report,
        date: today.iso8601,
        stats: stats
      }
    }
  end

  private

  # 尝试包裹查询
  def try_package_query(message)
    # 提取查询条件
    conditions = extract_query_conditions(message)

    return nil if conditions.empty?

    # 模拟查询包裹
    packages = simulate_package_search(conditions)

    if packages.any?
      response = format_package_response(packages)
      {
        success: true,
        data: {
          response: response,
          type: "package_query",
          packages: packages
        }
      }
    else
      {
        success: true,
        data: {
          response: "未找到符合条件的包裹。请检查查询条件是否正确，或尝试使用其他方式查询。",
          type: "package_query",
          packages: []
        }
      }
    end
  end

  # 提取查询条件
  def extract_query_conditions(message)
    conditions = {}

    # 提取手机号
    phone_match = message.match(/1[3-9]\d{9}/)
    conditions[:phone] = phone_match[0] if phone_match

    # 提取运单号
    tracking_match = message.match(/[A-Z]{2}\d{10,18}/i)
    conditions[:tracking_number] = tracking_match[0].upcase if tracking_match

    # 提取姓名（中文姓名）
    name_match = message.match(/[\u4e00-\u9fa5]{2,4}/)
    conditions[:name] = name_match[0] if name_match && !message.include?("地址")

    conditions
  end

  # 模拟包裹查询
  def simulate_package_search(conditions)
    # 模拟包裹数据
    mock_packages = [
      { id: 1, tracking_number: "SF123456789012", recipient_name: "张三",
        recipient_phone: "13800138000", courier_company: "顺丰速运",
        status: "pending", pickup_code: "05111234", stored_at: "2026-05-10 14:30:00" },
      { id: 2, tracking_number: "ZT987654321098", recipient_name: "李四",
        recipient_phone: "13900139000", courier_company: "中通快递",
        status: "picked_up", pickup_code: "05115678", stored_at: "2026-05-09 10:15:00", picked_up_at: "2026-05-10 16:45:00" },
      { id: 3, tracking_number: "YT555512345678", recipient_name: "王五",
        recipient_phone: "13700137000", courier_company: "圆通速递",
        status: "exception", pickup_code: "05119012", stored_at: "2026-05-08 09:20:00", exception_type: "address_error" },
      { id: 4, tracking_number: "ST112233445566", recipient_name: "赵六",
        recipient_phone: "13600136000", courier_company: "申通快递",
        status: "pending", pickup_code: "05113456", stored_at: "2026-05-11 08:30:00" }
    ]

    mock_packages.select do |pkg|
      match = true
      match &&= pkg[:recipient_phone] == conditions[:phone] if conditions[:phone]
      match &&= pkg[:tracking_number] == conditions[:tracking_number] if conditions[:tracking_number]
      match &&= pkg[:recipient_name] == conditions[:name] if conditions[:name]
      match
    end
  end

  # 格式化包裹查询响应
  def format_package_response(packages)
    status_labels = {
      pending: "待取件",
      picked_up: "已取件",
      exception: "异常",
      outbound: "已出库"
    }

    exception_labels = {
      address_error: "地址错误",
      damaged: "包裹破损",
      overdue: "逾期未取",
      no_such_person: "无人签收"
    }

    response = "📦 查询到 #{packages.size} 个包裹：\n\n"

    packages.each do |pkg|
      response += "---\n"
      response += "运单号：#{pkg[:tracking_number]}\n"
      response += "收件人：#{pkg[:recipient_name]}\n"
      response += "快递公司：#{pkg[:courier_company]}\n"
      response += "状态：#{status_labels[pkg[:status].to_sym] || pkg[:status]}\n"
      response += "取件码：#{pkg[:pickup_code]}\n" if pkg[:pickup_code]
      response += "存放时间：#{pkg[:stored_at]}\n" if pkg[:stored_at]
      response += "异常类型：#{exception_labels[pkg[:exception_type]&.to_sym] || pkg[:exception_type]}\n" if pkg[:exception_type]
      response += "已取件时间：#{pkg[:picked_up_at]}\n" if pkg[:picked_up_at]
    end

    response += "\n💡 提示：待取件包裹请凭取件码到驿站领取"
    response
  end

  # 尝试知识库匹配
  def try_knowledge_base_match(message)
    keywords_mapping = {
      /时间|营业|几点|开门|关门/ => :business_hours,
      /收费|费用|多少钱|价格|贵/ => :pricing,
      /取件|怎么取|流程|领取/ => :pickup_process,
      /联系|电话|地址|在哪里/ => :contact,
      /存放|保管|免费|超时/ => :storage_rules,
      /服务|项目|能做什么/ => :services
    }

    keywords_mapping.each do |pattern, key|
      if message.match?(pattern)
        knowledge = KNOWLEDGE_BASE[key]
        return {
          success: true,
          data: {
            response: "📋 **#{knowledge[:title]}**\n\n#{knowledge[:content]}",
            type: "knowledge",
            knowledge_key: key
          }
        }
      end
    end

    nil
  end

  # 尝试关键词匹配
  def try_keyword_match(message)
    # 问候语
    if message.match?(/你好|您好|嗨|Hello|Hi/)
      return {
        success: true,
        data: {
          response: "您好！我是菜鸟驿站AI助手，很高兴为您服务！\n\n请问有什么可以帮您？\n\n您可以问我：\n- 🕐 营业时间\n- 💰 收费标准\n- 📦 取件流程\n- 📞 联系方式",
          type: "greeting"
        }
      }
    end

    # 感谢语
    if message.match?(/谢谢|感谢|辛苦了/)
      return {
        success: true,
        data: {
          response: "不客气！很高兴能帮到您！😊\n\n如果还有其他问题，随时可以问我！",
          type: "thanks"
        }
      }
    end

    # 再见
    if message.match?(/再见|拜拜|结束|退出/)
      return {
        success: true,
        data: {
          response: "再见！祝您生活愉快！如有需要，随时回来找我！👋",
          type: "goodbye"
        }
      }
    end

    nil
  end

  # 默认回复
  def default_response
    {
      success: true,
      data: {
        response: "🎯 我理解您的问题了！\n\n以下是我可以帮助您的内容：\n\n📦 **包裹查询**\n- 输入运单号、手机号或姓名查询包裹状态\n\n📋 **驿站信息**\n- 营业时间、收费标准、取件流程、联系方式\n\n⚡ **快捷操作**\n- 点击下方快捷按钮快速获取信息\n\n如果您有具体问题，请详细描述，我会尽力帮您解答！",
        type: "default"
      }
    }
  end

  # 生成运营建议
  def generate_suggestions(stats)
    suggestions = []

    if stats[:pending] > 30
      suggestions << "⚠️ 待取件数量较多，建议通过短信通知用户及时取件"
    end

    if stats[:exceptions] > 10
      suggestions << "⚠️ 异常包裹较多，建议优先处理异常"
    end

    if stats[:delivered].to_f / stats[:today_packages] < 0.8
      suggestions << "💡 取件率有待提高，可以考虑增加取件提醒"
    end

    suggestions << "✅ 今日运营状况良好，继续保持！" if suggestions.empty?

    suggestions.join("\n")
  end
end
