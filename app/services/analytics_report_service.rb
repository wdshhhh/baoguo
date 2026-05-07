class AnalyticsReportService
  # 生成智能报表
  def generate_smart_report(report_type, date_range = {})
    begin
      start_date = date_range[:start_date] || 30.days.ago
      end_date = date_range[:end_date] || Time.current

      case report_type
      when :daily_summary
        generate_daily_summary(start_date, end_date)
      when :weekly_trends
        generate_weekly_trends(start_date, end_date)
      when :monthly_analysis
        generate_monthly_analysis(start_date, end_date)
      when :exception_analysis
        generate_exception_analysis(start_date, end_date)
      when :performance_metrics
        generate_performance_metrics(start_date, end_date)
      else
        generate_comprehensive_report(start_date, end_date)
      end
    rescue => e
      {
        success: false,
        error: "报表生成失败: #{e.message}"
      }
    end
  end

  # 生成每日摘要
  def generate_daily_summary(start_date, end_date)
    packages_today = Package.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    exceptions_today = PackageException.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      success: true,
      data: {
        report_type: "daily_summary",
        date_range: {
          start: start_date.strftime("%Y-%m-%d"),
          end: end_date.strftime("%Y-%m-%d")
        },
        summary: {
          total_packages: packages_today.count,
          packages_stored: packages_today.where(status: :stored).count,
          packages_picked_up: packages_today.where(status: :picked_up).count,
          new_exceptions: exceptions_today.count,
          resolved_exceptions: exceptions_today.where(status: :resolved).count
        },
        trends: calculate_daily_trends_manual(start_date, end_date),
        insights: generate_daily_insights(packages_today, exceptions_today),
        recommendations: generate_daily_recommendations(packages_today, exceptions_today)
      }
    }
  end

  # 生成周度趋势
  def generate_weekly_trends(start_date, end_date)
    weekly_data = Package.where(created_at: start_date..end_date)
                        .group_by_week(:created_at)
                        .count

    weekly_exceptions = PackageException.where(created_at: start_date..end_date)
                                       .group_by_week(:created_at)
                                       .count

    {
      success: true,
      data: {
        report_type: "weekly_trends",
        date_range: {
          start: start_date.strftime("%Y-%m-%d"),
          end: end_date.strftime("%Y-%m-%d")
        },
        weekly_packages: weekly_data,
        weekly_exceptions: weekly_exceptions,
        avg_weekly_packages: weekly_data.values.sum / [ weekly_data.size, 1 ].max,
        trend_analysis: analyze_weekly_trend(weekly_data),
        peak_periods: identify_peak_periods(start_date, end_date)
      }
    }
  end

  # 生成月度分析
  def generate_monthly_analysis(start_date, end_date)
    monthly_stats = calculate_monthly_statistics(start_date, end_date)

    {
      success: true,
      data: {
        report_type: "monthly_analysis",
        date_range: {
          start: start_date.strftime("%Y-%m-%d"),
          end: end_date.strftime("%Y-%m-%d")
        },
        monthly_summary: monthly_stats,
        package_type_distribution: package_type_distribution(start_date, end_date),
        exception_type_distribution: exception_type_distribution(start_date, end_date),
        customer_behavior: analyze_customer_behavior(start_date, end_date),
        operational_efficiency: calculate_operational_efficiency(start_date, end_date)
      }
    }
  end

  # 生成异常分析报告
  def generate_exception_analysis(start_date, end_date)
    exceptions = PackageException.where(created_at: start_date..end_date)

    {
      success: true,
      data: {
        report_type: "exception_analysis",
        date_range: {
          start: start_date.strftime("%Y-%m-%d"),
          end: end_date.strftime("%Y-%m-%d")
        },
        exception_stats: {
          total: exceptions.count,
          by_type: exceptions.group(:exception_type).count,
          by_status: exceptions.group(:status).count,
          resolution_time: calculate_avg_resolution_time(exceptions)
        },
        root_cause_analysis: analyze_exception_root_causes(exceptions),
        prevention_recommendations: generate_exception_prevention_recommendations(exceptions),
        high_risk_patterns: identify_high_risk_patterns(exceptions)
      }
    }
  end

  # 生成性能指标
  def generate_performance_metrics(start_date, end_date)
    {
      success: true,
      data: {
        report_type: "performance_metrics",
        date_range: {
          start: start_date.strftime("%Y-%m-%d"),
          end: end_date.strftime("%Y-%m-%d")
        },
        kpis: {
          storage_efficiency: calculate_storage_efficiency(start_date, end_date),
          pickup_rate: calculate_pickup_rate(start_date, end_date),
          exception_rate: calculate_exception_rate(start_date, end_date),
          customer_satisfaction: estimate_customer_satisfaction(start_date, end_date),
          operational_cost: estimate_operational_cost(start_date, end_date)
        },
        benchmarks: generate_benchmarks(start_date, end_date),
        improvement_opportunities: identify_improvement_opportunities(start_date, end_date)
      }
    }
  end

  # 计算月度统计
  def calculate_monthly_statistics(start_date, end_date)
    packages = Package.where(created_at: start_date..end_date)
    exceptions = PackageException.where(created_at: start_date..end_date)

    {
      total_packages: packages.count,
      avg_daily_packages: packages.count / [ (end_date - start_date).to_i, 1 ].max,
      pickup_rate: (packages.where(status: :picked_up).count.to_f / packages.count * 100).round(2),
      avg_storage_duration: calculate_avg_storage_duration(packages),
      exception_rate: (exceptions.count.to_f / packages.count * 100).round(2),
      revenue_estimation: estimate_revenue(packages)
    }
  end

  # 分析周度趋势
  def analyze_weekly_trend(weekly_data)
    return "数据不足" if weekly_data.size < 2

    recent_weeks = weekly_data.values.last(4)
    trend = recent_weeks.each_cons(2).map { |a, b| b - a }.sum / 3.0

    if trend > 5
      "上升趋势"
    elsif trend < -5
      "下降趋势"
    else
      "平稳趋势"
    end
  end

  # 识别高峰期
  def identify_peak_periods(start_date, end_date)
    hourly_distribution = group_by_hour_manual(Package.where(created_at: start_date..end_date), :created_at)

    avg_per_hour = hourly_distribution.values.sum / 24.0
    peak_hours = hourly_distribution.select { |_, count| count > avg_per_hour * 1.5 }

    peak_hours.transform_keys { |hour| "#{hour}:00" }
  end

  # 包裹类型分布
  def package_type_distribution(start_date, end_date)
    Package.where(created_at: start_date..end_date)
           .group(:package_type)
           .count
           .transform_keys { |k| Package.package_types.key(k) }
  end

  # 异常类型分布
  def exception_type_distribution(start_date, end_date)
    PackageException.where(created_at: start_date..end_date)
                   .group(:exception_type)
                   .count
                   .transform_keys { |k| PackageException.exception_types.key(k) }
  end

  # 分析客户行为
  def analyze_customer_behavior(start_date, end_date)
    frequent_customers = Package.where(created_at: start_date..end_date)
                               .group(:recipient_phone)
                               .having("COUNT(*) > 3")
                               .count
                               .size

    avg_pickup_time = calculate_avg_pickup_time(start_date, end_date)

    {
      frequent_customers: frequent_customers,
      avg_pickup_time_hours: avg_pickup_time,
      customer_retention_rate: calculate_retention_rate(start_date, end_date)
    }
  end

  # 计算运营效率
  def calculate_operational_efficiency(start_date, end_date)
    packages_per_day = Package.where(created_at: start_date..end_date).count / [ (end_date - start_date).to_i, 1 ].max
    exceptions_per_day = PackageException.where(created_at: start_date..end_date).count / [ (end_date - start_date).to_i, 1 ].max

    {
      packages_per_day: packages_per_day.round(1),
      exceptions_per_day: exceptions_per_day.round(1),
      efficiency_score: calculate_efficiency_score(packages_per_day, exceptions_per_day)
    }
  end

  # 生成每日洞察
  def generate_daily_insights(packages, exceptions)
    insights = []

    if packages.where(status: :stored).count > 10
      insights << "今日有较多包裹待取件，建议发送取件提醒"
    end

    if exceptions.count > 5
      insights << "今日异常数量较多，需要重点关注处理"
    end

    if packages.where(package_type: "fragile").count > 3
      insights << "易碎包裹较多，请加强防护措施"
    end

    insights.empty? ? [ "今日运营平稳" ] : insights
  end

  # 生成每日建议
  def generate_daily_recommendations(packages, exceptions)
    recommendations = []

    long_storage = packages.where(status: :stored).where("created_at < ?", 3.days.ago)
    if long_storage.count > 0
      recommendations << "有#{long_storage.count}个包裹存储超过3天，建议联系客户"
    end

    pending_exceptions = exceptions.where(status: :pending)
    if pending_exceptions.count > 0
      recommendations << "有#{pending_exceptions.count}个异常待处理，请及时处理"
    end

    recommendations.empty? ? [ "继续保持良好运营" ] : recommendations
  end

  # 预测未来趋势
  def predict_future_trends(historical_data, days_ahead = 7)
    # 简单的线性回归预测
    return "数据不足" if historical_data.size < 5

    x_data = (0...historical_data.size).to_a
    y_data = historical_data.values

    # 计算斜率和截距
    n = x_data.size
    sum_x = x_data.sum
    sum_y = y_data.sum
    sum_xy = x_data.zip(y_data).map { |x, y| x * y }.sum
    sum_x2 = x_data.map { |x| x * x }.sum

    slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x).to_f
    intercept = (sum_y - slope * sum_x) / n.to_f

    # 预测未来值
    future_predictions = {}
    days_ahead.times do |i|
      future_day = historical_data.size + i
      predicted_value = (slope * future_day + intercept).round
      future_predictions["day_#{i+1}"] = [ predicted_value, 0 ].max
    end

    future_predictions
  end

  # 智能报表可视化数据
  def generate_visualization_data(report_type, date_range)
    case report_type
    when :package_flow
      generate_package_flow_data(date_range)
    when :exception_trends
      generate_exception_trends_data(date_range)
    when :customer_analysis
      generate_customer_analysis_data(date_range)
    else
      generate_comprehensive_visualization_data(date_range)
    end
  end

  private

  # 计算平均存储时长（小时）
  def calculate_avg_storage_duration(packages)
    picked_up_packages = packages.where(status: :picked_up)
    return 0 if picked_up_packages.empty?

    total_hours = picked_up_packages.sum do |pkg|
      (pkg.updated_at - pkg.created_at) / 3600  # 转换为小时
    end

    (total_hours / picked_up_packages.count).round(1)
  end

  # 估算收入
  def estimate_revenue(packages)
    # 简单的收入估算模型
    base_revenue = packages.count * 0.5  # 假设每个包裹平均收入0.5元
    (base_revenue * 30).round(2)  # 月收入估算
  end

  # 计算平均取件时间
  def calculate_avg_pickup_time(start_date, end_date)
    picked_up_packages = Package.where(status: :picked_up, created_at: start_date..end_date)
    return 0 if picked_up_packages.empty?

    total_hours = picked_up_packages.sum do |pkg|
      (pkg.updated_at - pkg.created_at) / 3600
    end

    (total_hours / picked_up_packages.count).round(1)
  end

  # 计算客户留存率
  def calculate_retention_rate(start_date, end_date)
    # 简化的留存率计算
    total_customers = Package.where(created_at: start_date..end_date).distinct.count(:recipient_phone)
    return 0 if total_customers.zero?

    repeat_customers = Package.where(created_at: start_date..end_date)
                             .group(:recipient_phone)
                             .having("COUNT(*) > 1")
                             .count
                             .size

    (repeat_customers.to_f / total_customers * 100).round(2)
  end

  # 计算效率分数
  def calculate_efficiency_score(packages_per_day, exceptions_per_day)
    base_score = 100

    # 异常率扣分
    exception_penalty = (exceptions_per_day / [ packages_per_day, 1 ].max * 50).round

    # 包裹量加分（但有限制）
    volume_bonus = [ packages_per_day / 10, 20 ].min

    final_score = base_score - exception_penalty + volume_bonus
    [ final_score, 0 ].max
  end

  # 生成包裹流量数据
  def generate_package_flow_data(date_range)
    packages = Package.where(created_at: date_range[:start_date]..date_range[:end_date])

    {
      daily_flow: group_by_day_manual(packages, :created_at),
      hourly_flow: group_by_hour_manual(packages, :created_at),
      status_distribution: packages.group(:status).count,
      type_distribution: packages.group(:package_type).count
    }
  end

  # 生成异常趋势数据
  def generate_exception_trends_data(date_range)
    exceptions = PackageException.where(created_at: date_range[:start_date]..date_range[:end_date])

    {
      daily_trends: group_by_day_manual(exceptions, :created_at),
      type_trends: group_by_day_and_type_manual(exceptions),
      resolution_trends: group_by_day_manual(exceptions.where.not(resolved_at: nil), :resolved_at)
    }
  end

  # 生成客户分析数据
  def generate_customer_analysis_data(date_range)
    customers = Package.where(created_at: date_range[:start_date]..date_range[:end_date])
                      .group(:recipient_phone)
                      .count

    {
      customer_segments: {
        frequent: customers.count { |_, count| count > 3 },
        occasional: customers.count { |_, count| count.between?(2, 3) },
        one_time: customers.count { |_, count| count == 1 }
      },
      top_customers: customers.sort_by { |_, count| -count }.first(10).to_h
    }
  end

  # 生成综合可视化数据
  def generate_comprehensive_visualization_data(date_range)
    {
      package_flow: generate_package_flow_data(date_range),
      exception_trends: generate_exception_trends_data(date_range),
      customer_analysis: generate_customer_analysis_data(date_range)
    }
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

  # 手动按天和类型分组
  def group_by_day_and_type_manual(exceptions)
    result = {}
    exceptions.each do |exception|
      date = exception.created_at.to_date.to_s
      type = exception.exception_type

      result[date] ||= {}
      result[date][type] ||= 0
      result[date][type] += 1
    end
    result
  end

  # 手动计算每日趋势
  def calculate_daily_trends_manual(start_date, end_date)
    packages = Package.where(created_at: start_date..end_date)
    exceptions = PackageException.where(created_at: start_date..end_date)

    {
      package_trend: group_by_day_manual(packages, :created_at),
      exception_trend: group_by_day_manual(exceptions, :created_at),
      pickup_trend: group_by_day_manual(packages.where(status: :picked_up), :updated_at)
    }
  end

  # 计算平均异常解决时间（小时）
  def calculate_avg_resolution_time(exceptions)
    resolved_exceptions = exceptions.where(status: :resolved).where.not(resolved_at: nil)
    return 0 if resolved_exceptions.empty?

    total_hours = resolved_exceptions.sum do |exception|
      (exception.resolved_at - exception.created_at) / 3600  # 转换为小时
    end

    (total_hours / resolved_exceptions.count).round(1)
  end

  # 分析异常根本原因
  def analyze_exception_root_causes(exceptions)
    # 简化的根本原因分析
    causes = {}

    exceptions.each do |exception|
      cause = case exception.exception_type
      when "damaged" then "包裹损坏"
      when "missing" then "包裹丢失"
      when "wrong_address" then "地址错误"
      when "recipient_refused" then "收件人拒收"
      else "其他原因"
      end

      causes[cause] ||= 0
      causes[cause] += 1
    end

    causes
  end

  # 生成异常预防建议
  def generate_exception_prevention_recommendations(exceptions)
    recommendations = []

    if exceptions.where(exception_type: "damaged").count > 0
      recommendations << "加强包裹包装防护措施"
    end

    if exceptions.where(exception_type: "missing").count > 0
      recommendations << "完善包裹追踪系统"
    end

    if exceptions.where(exception_type: "wrong_address").count > 0
      recommendations << "加强地址信息验证"
    end

    recommendations.empty? ? [ "当前异常预防措施良好" ] : recommendations
  end

  # 识别高风险模式
  def identify_high_risk_patterns(exceptions)
    patterns = {}

    # 按时间段分析
    peak_hours = exceptions.group_by { |e| e.created_at.hour }
                           .transform_values(&:count)
                           .select { |_, count| count > exceptions.count / 24 }

    patterns[:peak_hours] = peak_hours.keys if peak_hours.any?

    # 按包裹类型分析
    package_types = exceptions.joins(:package).group("packages.package_type").count
    patterns[:high_risk_types] = package_types.select { |_, count| count > exceptions.count / 5 }.keys

    patterns
  end
end
