class ExceptionPredictionService
  # 异常预测分析
  def predict_exceptions
    begin
      # 获取历史异常数据
      historical_data = collect_historical_data

      # 分析当前包裹状态
      current_packages = analyze_current_packages

      # 预测潜在异常
      predictions = generate_predictions(historical_data, current_packages)

      {
        success: true,
        data: {
          high_risk_packages: predictions[:high_risk],
          medium_risk_packages: predictions[:medium_risk],
          low_risk_packages: predictions[:low_risk],
          overall_risk_level: predictions[:overall_risk],
          prediction_confidence: predictions[:confidence]
        }
      }
    rescue => e
      {
        success: false,
        error: "异常预测失败: #{e.message}"
      }
    end
  end

  # 收集历史数据
  def collect_historical_data
    # 过去30天的异常数据
    start_date = 30.days.ago

    {
      total_packages: Package.where(created_at: start_date..Time.current).count,
      total_exceptions: PackageException.where(created_at: start_date..Time.current).count,
      exception_types: PackageException.where(created_at: start_date..Time.current)
                                      .group(:exception_type)
                                      .count,
      exception_trends: group_by_day_manual(PackageException.where(created_at: start_date..Time.current), :created_at)
    }
  end

  # 分析当前包裹状态
  def analyze_current_packages
    # 待入库包裹
    pending_packages = Package.where(status: :pending)

    # 已入库但未取件超过3天的包裹
    stored_long_time = Package.where(status: :stored)
                              .where("created_at < ?", 3.days.ago)

    # 大件和易碎包裹
    special_packages = Package.where(package_type: [ "large", "fragile" ])
                              .where(status: [ :pending, :stored ])

    {
      pending_count: pending_packages.count,
      stored_long_time_count: stored_long_time.count,
      special_packages_count: special_packages.count,
      pending_packages: pending_packages,
      stored_long_time_packages: stored_long_time,
      special_packages: special_packages
    }
  end

  # 生成预测
  def generate_predictions(historical_data, current_packages)
    high_risk = []
    medium_risk = []
    low_risk = []

    # 分析每个包裹的风险
    analyze_package_risks(current_packages, high_risk, medium_risk, low_risk)

    # 计算整体风险等级
    overall_risk = calculate_overall_risk(high_risk, medium_risk, low_risk)

    {
      high_risk: high_risk,
      medium_risk: medium_risk,
      low_risk: low_risk,
      overall_risk: overall_risk,
      confidence: calculate_prediction_confidence(historical_data)
    }
  end

  # 分析包裹风险
  def analyze_package_risks(current_packages, high_risk, medium_risk, low_risk)
    # 分析待入库包裹
    current_packages[:pending_packages].each do |package|
      risk_level = assess_package_risk(package)

      case risk_level
      when :high
        high_risk << package_risk_info(package, risk_level)
      when :medium
        medium_risk << package_risk_info(package, risk_level)
      else
        low_risk << package_risk_info(package, risk_level)
      end
    end

    # 分析长期存储包裹
    current_packages[:stored_long_time_packages].each do |package|
      risk_info = package_risk_info(package, :medium)
      risk_info[:risk_reason] = "包裹已存储超过3天未取件"
      medium_risk << risk_info
    end

    # 分析特殊包裹
    current_packages[:special_packages].each do |package|
      risk_level = package.package_type == "fragile" ? :high : :medium
      risk_info = package_risk_info(package, risk_level)
      risk_info[:risk_reason] = "#{package.package_type}包裹需要特殊处理"

      case risk_level
      when :high
        high_risk << risk_info
      when :medium
        medium_risk << risk_info
      end
    end
  end

  # 评估单个包裹风险
  def assess_package_risk(package)
    risk_score = 0

    # 包裹类型风险
    case package.package_type
    when "fragile"
      risk_score += 30
    when "large"
      risk_score += 15
    when "priority"
      risk_score += 10
    end

    # 等待时间风险
    wait_hours = (Time.current - package.created_at).to_i / 3600
    if wait_hours > 24
      risk_score += (wait_hours - 24) * 2  # 超过24小时每小时加2分
    end

    # 历史异常模式风险（如果有历史数据）
    risk_score += assess_historical_pattern_risk(package)

    # 确定风险等级
    if risk_score >= 40
      :high
    elsif risk_score >= 20
      :medium
    else
      :low
    end
  end

  # 评估历史模式风险
  def assess_historical_pattern_risk(package)
    # 检查相似包裹的历史异常率
    similar_packages = Package.where(
      package_type: package.package_type,
      recipient_phone: package.recipient_phone
    ).where.not(id: package.id)

    return 0 if similar_packages.empty?

    exception_rate = PackageException.where(package_id: similar_packages.pluck(:id)).count.to_f / similar_packages.count

    # 根据异常率加分
    (exception_rate * 50).to_i  # 最大加50分
  end

  # 包裹风险信息
  def package_risk_info(package, risk_level)
    {
      package_id: package.id,
      tracking_number: package.tracking_number,
      recipient_name: package.recipient_name,
      package_type: package.package_type,
      status: package.status,
      created_at: package.created_at,
      risk_level: risk_level,
      risk_score: calculate_risk_score(package, risk_level)
    }
  end

  # 计算风险分数
  def calculate_risk_score(package, risk_level)
    base_score = case risk_level
    when :high then 80
    when :medium then 50
    else 20
    end

    # 根据等待时间调整分数
    wait_hours = (Time.current - package.created_at).to_i / 3600
    base_score + [ wait_hours * 2, 20 ].min
  end

  # 计算整体风险等级
  def calculate_overall_risk(high_risk, medium_risk, low_risk)
    total_risk = high_risk.size * 3 + medium_risk.size * 2 + low_risk.size

    if high_risk.size >= 3 || total_risk >= 10
      "high"
    elsif medium_risk.size >= 5 || total_risk >= 5
      "medium"
    else
      "low"
    end
  end

  # 计算预测置信度
  def calculate_prediction_confidence(historical_data)
    # 基于历史数据量计算置信度
    total_data_points = historical_data[:total_packages] + historical_data[:total_exceptions]

    if total_data_points >= 1000
      0.95
    elsif total_data_points >= 100
      0.85
    elsif total_data_points >= 50
      0.75
    else
      0.65
    end
  end

  # 实时预警检查
  def real_time_alerts
    alerts = []

    # 检查异常包裹
    PackageException.where(status: [ :pending, :processing ]).each do |exception|
      if exception.created_at < 2.hours.ago && exception.status == "pending"
        alerts << {
          type: "exception_pending",
          message: "异常处理待处理超过2小时",
          package_tracking_number: exception.package.tracking_number,
          severity: "high"
        }
      end
    end

    # 检查长期未取件包裹
    Package.where(status: :stored).where("created_at < ?", 7.days.ago).each do |package|
      alerts << {
        type: "long_storage",
        message: "包裹存储超过7天未取件",
        package_tracking_number: package.tracking_number,
        severity: "medium"
      }
    end

    alerts
  end

  # 计算平均解决时间
  def calculate_avg_resolution_time(exceptions)
    resolved_exceptions = exceptions.where(status: :resolved)
    return 0 if resolved_exceptions.empty?

    total_time = resolved_exceptions.sum do |exception|
      (exception.resolved_at - exception.created_at) / 3600.0  # 转换为小时
    end

    (total_time / resolved_exceptions.count).round(1)
  end

  # 分析异常根因
  def analyze_exception_root_causes(exceptions)
    causes = Hash.new(0)

    exceptions.each do |exception|
      case exception.exception_type
      when "overdue"
        causes["逾期未取"] += 1
      when "damaged"
        causes["包裹破损"] += 1
      when "wrong_delivery"
        causes["投递错误"] += 1
      when "lost"
        causes["包裹丢失"] += 1
      else
        causes["其他原因"] += 1
      end
    end

    causes.sort_by { |_, count| -count }.to_h
  end

  # 生成异常预防建议
  def generate_exception_prevention_recommendations(exceptions)
    recommendations = []

    overdue_count = exceptions.where(exception_type: "overdue").count
    if overdue_count > 0
      recommendations << "加强逾期包裹提醒机制，建议设置自动提醒系统"
    end

    damaged_count = exceptions.where(exception_type: "damaged").count
    if damaged_count > 0
      recommendations << "加强包裹防护措施，对易碎物品进行特殊标识"
    end

    wrong_delivery_count = exceptions.where(exception_type: "wrong_delivery").count
    if wrong_delivery_count > 0
      recommendations << "优化投递流程，加强地址信息核对"
    end

    recommendations.empty? ? [ "当前异常预防措施有效" ] : recommendations
  end

  # 识别高风险模式
  def identify_high_risk_patterns(exceptions)
    patterns = []

    # 检查特定时间段的高发异常
    peak_hours = group_by_hour_manual(exceptions, :created_at)
    peak_hours.each do |hour, count|
      if count >= 3  # 同一小时超过3个异常
        patterns << "#{hour}:00时段异常高发，建议加强监控"
      end
    end

    # 检查特定包裹类型的异常模式
    type_patterns = exceptions.group(:exception_type).count
    type_patterns.each do |type, count|
      if count >= exceptions.count * 0.3  # 占比超过30%
        patterns << "#{type}类型异常占比过高，需要重点关注"
      end
    end

    patterns.empty? ? [ "未发现明显高风险模式" ] : patterns
  end

  private

  # 手动按天分组
  def group_by_day_manual(relation, column)
    result = {}
    relation.each do |record|
      date = record.send(column).to_date.to_s
      result[date] ||= 0
      result[date] += 1
    end
    result
  end

  # 手动按小时分组
  def group_by_hour_manual(relation, column)
    result = {}
    relation.each do |record|
      hour = record.send(column).hour
      result[hour] ||= 0
      result[hour] += 1
    end
    result
  end
end
