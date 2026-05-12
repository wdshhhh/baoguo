module Api
  module V1
    class StatisticsController < BaseController
      before_action :authenticate_user!

      # 缓存存储
      @@statistics_cache = {}
      @@cache_expiry = 5.minutes

      # GET /api/v1/statistics/summary
      # 获取统计摘要
      def summary
        start_date, end_date = parse_date_range(params)
        use_cache = params[:use_cache] != "false"

        cache_key = "summary_#{start_date}_#{end_date}"
        cached_data = use_cache ? get_cached_data(cache_key) : nil
        is_cached = !cached_data.nil?

        if cached_data
          cached_data[:cached] = true
          return render_json(cached_data)
        end

        begin
          # 本月总数：查询包裹表 created_at 在时间范围内且未被删除
          total_count = Package.where(deleted_at: nil).where(created_at: start_date.beginning_of_day..end_date.end_of_day).count

          # 本月出库数：查询出库时间 outbound_at 在时间范围内
          outbound_count = Package.where(outbound_at: start_date.beginning_of_day..end_date.end_of_day).count

          # 异常包裹数：状态为异常的包裹
          exception_count = Package.where(deleted_at: nil).where(status: :exception).count

          # 异常率：异常包裹数 / 总包裹数 * 100%
          exception_rate = total_count > 0 ? ((exception_count.to_f / total_count) * 100).round(1) : 0

          # 出库率：已出库包裹数 / (总包裹数 - 异常未解决包裹数) * 100%
          valid_total = total_count - exception_count
          outbound_rate = valid_total > 0 ? ((outbound_count.to_f / valid_total) * 100).round(1) : 0

          # 包裹状态分布（未删除的）：待入库、已入库、已出库、异常
          status_distribution = Package.where(deleted_at: nil).group(:status).count

          # 转换状态为中文名称
          status_names = {
            pending: "待入库",
            stored: "已入库",
            picked_up: "已出库",
            exception: "异常"
          }
          formatted_status_dist = {}
          [ :pending, :stored, :picked_up, :exception ].each do |status|
            formatted_status_dist[status_names[status]] = status_distribution[Package.statuses[status]] || 0
          end

          # 快递公司占比（只显示Top5，其他归为"其他"）
          courier_distribution = Package.where(deleted_at: nil).where.not(courier_company: nil).group(:courier_company).count
          courier_distribution = courier_distribution.sort_by { |_, v| -v }.first(5).to_h
          other_count = Package.where(deleted_at: nil).where.not(courier_company: courier_distribution.keys).count
          courier_distribution["其他"] = other_count if other_count > 0

          result = {
            total_count: total_count,
            outbound_count: outbound_count,
            exception_count: exception_count,
            outbound_rate: outbound_rate,
            exception_rate: exception_rate,
            status_distribution: formatted_status_dist,
            courier_distribution: courier_distribution,
            cached: false
          }

          cache_data(cache_key, result) if use_cache
          render_json(result)
        rescue => e
          Rails.logger.error("获取统计摘要失败: #{e.message}")
          render_error("获取统计摘要失败: #{e.message}")
        end
      end

      # GET /api/v1/statistics/trend
      # 获取趋势数据
      def trend
        days = (params[:days] || 7).to_i
        days = [ 7, 30 ].include?(days) ? days : 7
        use_cache = params[:use_cache] != "false"

        cache_key = "trend_#{days}"
        cached_data = use_cache ? get_cached_data(cache_key) : nil

        if cached_data
          cached_data[:cached] = true
          return render_json(cached_data)
        end

        begin
          # 获取指定天数的数据
          trend_data = []
          (days - 1).downto(0) do |i|
            date = (Date.today - i).to_date
            # 入库数：created_at在当天且未删除
            inbound_count = Package.where(deleted_at: nil).where(created_at: date.beginning_of_day..date.end_of_day).count
            # 出库数：使用outbound_at字段
            outbound_count = Package.where(outbound_at: date.beginning_of_day..date.end_of_day).count

            trend_data << {
              date: date.strftime("%m-%d"),
              date_full: date.strftime("%Y-%m-%d"),
              inbound: inbound_count,
              outbound: outbound_count
            }
          end

          result = { days: days, data: trend_data, cached: false }
          cache_data(cache_key, result) if use_cache
          render_json(result)
        rescue => e
          Rails.logger.error("获取趋势数据失败: #{e.message}")
          render_error("获取趋势数据失败: #{e.message}")
        end
      end

      # GET /api/v1/statistics/package_by_courier
      # 获取指定快递公司的包裹列表
      def package_by_courier
        courier_company = params[:courier_company]
        return render_error("请指定快递公司") unless courier_company.present?

        begin
          packages = Package.where(deleted_at: nil).where(courier_company: courier_company)
                           .order(created_at: :desc)
                           .page(params[:page] || 1)
                           .per(params[:per_page] || 20)

          render_json({
            data: packages.map { |p| p.as_json(only: [ :id, :tracking_number, :recipient_name, :recipient_phone, :status, :created_at ]) },
            meta: {
              total: packages.total_count,
              page: packages.current_page,
              per_page: packages.limit_value
            }
          })
        rescue => e
          Rails.logger.error("获取快递公司包裹列表失败: #{e.message}")
          render_error("获取快递公司包裹列表失败: #{e.message}")
        end
      end

      # GET /api/v1/statistics/weight_distribution
      # 获取包裹重量分布
      def weight_distribution
        begin
          # 按重量区间统计
          weight_ranges = [
            { name: "0-0.5kg", min: 0, max: 0.5 },
            { name: "0.5-1kg", min: 0.5, max: 1 },
            { name: "1-2kg", min: 1, max: 2 },
            { name: "2-5kg", min: 2, max: 5 },
            { name: "5kg以上", min: 5, max: Float::INFINITY }
          ]

          distribution = weight_ranges.map do |range|
            count = Package.where(deleted_at: nil)
                          .where("weight > ? AND weight <= ?", range[:min], range[:max])
                          .count
            { name: range[:name], count: count }
          end

          render_json({ data: distribution })
        rescue => e
          Rails.logger.error("获取重量分布失败: #{e.message}")
          render_error("获取重量分布失败: #{e.message}")
        end
      end

      # POST /api/v1/statistics/export
      # 导出统计数据
      def export
        start_date, end_date = parse_date_range(params)
        format = params[:format] || "excel"

        begin
          # 获取统计数据
          summary_data = get_summary_data(start_date, end_date)
          trend_data = get_trend_data(start_date, end_date, 30)

          if format == "excel"
            export_to_excel(summary_data, trend_data, start_date, end_date)
          else
            render_error("不支持的导出格式")
          end
        rescue => e
          Rails.logger.error("导出统计数据失败: #{e.message}")
          render_error("导出统计数据失败: #{e.message}")
        end
      end

      private

      def parse_date_range(params)
        range_type = params[:range_type] || "current_month"

        case range_type
        when "current_month"
          [ Time.current.beginning_of_month.to_date, Time.current.end_of_month.to_date ]
        when "last_month"
          [ Time.current.last_month.beginning_of_month.to_date, Time.current.last_month.end_of_month.to_date ]
        when "last_3_months"
          [ 3.months.ago.beginning_of_month.to_date, Time.current.end_of_month.to_date ]
        when "custom"
          start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today - 30
          end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today
          [ start_date, end_date ]
        else
          [ Time.current.beginning_of_month.to_date, Time.current.end_of_month.to_date ]
        end
      end

      def get_cached_data(key)
        cached = @@statistics_cache[key]
        return nil unless cached
        return cached[:data] if Time.current - cached[:timestamp] < @@cache_expiry
        @@statistics_cache.delete(key)
        nil
      end

      def cache_data(key, data)
        @@statistics_cache[key] = {
          data: data,
          timestamp: Time.current
        }
      end

      def get_summary_data(start_date, end_date)
        total_count = Package.where(deleted_at: nil).where(created_at: start_date.beginning_of_day..end_date.end_of_day).count
        outbound_count = Package.where(outbound_at: start_date.beginning_of_day..end_date.end_of_day).count
        exception_count = Package.where(deleted_at: nil).where(status: :exception).count
        valid_total = total_count - exception_count
        outbound_rate = valid_total > 0 ? ((outbound_count.to_f / valid_total) * 100).round(1) : 0
        exception_rate = total_count > 0 ? ((exception_count.to_f / total_count) * 100).round(1) : 0

        status_distribution = Package.where(deleted_at: nil).group(:status).count
        formatted_status_dist = {}
        { pending: "待入库", stored: "已入库", picked_up: "已出库", exception: "异常" }.each do |status, name|
          formatted_status_dist[name] = status_distribution[Package.statuses[status]] || 0
        end

        courier_distribution = Package.where(deleted_at: nil).where.not(courier_company: nil).group(:courier_company).count
        courier_distribution = courier_distribution.sort_by { |_, v| -v }.first(5).to_h
        other_count = Package.where(deleted_at: nil).where.not(courier_company: courier_distribution.keys).count
        courier_distribution["其他"] = other_count if other_count > 0

        {
          total_count: total_count,
          outbound_count: outbound_count,
          exception_count: exception_count,
          outbound_rate: outbound_rate,
          exception_rate: exception_rate,
          status_distribution: formatted_status_dist,
          courier_distribution: courier_distribution,
          date_range: "#{start_date} 至 #{end_date}"
        }
      end

      def get_trend_data(start_date, end_date, days)
        trend_data = []
        (days - 1).downto(0) do |i|
          date = (Date.today - i).to_date
          inbound_count = Package.where(deleted_at: nil).where(created_at: date.beginning_of_day..date.end_of_day).count
          outbound_count = Package.where(outbound_at: date.beginning_of_day..date.end_of_day).count
          trend_data << { date: date.strftime("%Y-%m-%d"), inbound: inbound_count, outbound: outbound_count }
        end
        trend_data
      end

      def export_to_excel(summary_data, trend_data, start_date, end_date)
        require "roo"
        require "tempfile"

        # 创建Excel文件
        workbook = Spreadsheet::Workbook.new
        sheet = workbook.create_worksheet(name: "统计报表")

        # 标题
        sheet.row(0).concat([ "统计报表", "", "", "", "时间范围: #{start_date} 至 #{end_date}" ])

        # 统计摘要
        sheet.row(2).concat([ "统计摘要", "", "", "", "" ])
        sheet.row(3).concat([ "本月包裹总数", summary_data[:total_count] ])
        sheet.row(4).concat([ "本月出库数", summary_data[:outbound_count] ])
        sheet.row(5).concat([ "出库率", "#{summary_data[:outbound_rate]}%" ])

        # 包裹状态分布
        sheet.row(7).concat([ "包裹状态分布", "", "", "", "" ])
        sheet.row(8).concat([ "状态", "数量" ])
        summary_data[:status_distribution].each_with_index do |(status, count), index|
          sheet.row(9 + index).concat([ status, count ])
        end

        # 快递公司分布
        sheet.row(15).concat([ "快递公司分布", "", "", "", "" ])
        sheet.row(16).concat([ "快递公司", "数量" ])
        summary_data[:courier_distribution].each_with_index do |(courier, count), index|
          sheet.row(17 + index).concat([ courier, count ])
        end

        # 趋势数据
        sheet.row(25).concat([ "每日趋势", "", "", "", "" ])
        sheet.row(26).concat([ "日期", "入库数", "出库数" ])
        trend_data.each_with_index do |item, index|
          sheet.row(27 + index).concat([ item[:date], item[:inbound], item[:outbound] ])
        end

        # 写入临时文件
        temp_file = Tempfile.new([ "statistics_#{start_date}_#{end_date}", ".xls" ])
        workbook.write(temp_file.path)
        temp_file.close

        # 发送文件
        send_file(
          temp_file.path,
          filename: "统计报表_#{start_date}_#{end_date}.xls",
          type: "application/vnd.ms-excel",
          disposition: "attachment"
        )
      rescue LoadError
        # 如果没有安装spreadsheet gem，返回JSON数据
        render_json({
          message: "导出成功",
          summary: summary_data,
          trend: trend_data
        })
      end
    end
  end
end
