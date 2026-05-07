module Api
  module V1
    class DashboardController < BaseController
      skip_before_action :authenticate_user!, only: [ :stats, :chart_data, :recent_activities ]

      def stats
        today = Time.current.beginning_of_day..Time.current.end_of_day

        stats = {
          today_stored: Package.where(stored_at: today).count,
          today_picked_up: Package.where(picked_up_at: today).count,
          exception_count: PackageException.where(status: :pending).count,
          pending_count: Package.where(status: :stored).count,
          total_packages: Package.count,
          today_revenue: calculate_today_revenue
        }

        render json: { success: true, data: stats }
      end

      def chart_data
        # 获取最近7天的数据
        days = 7.days.ago.to_date..Date.today

        stored_data = days.map do |date|
          Package.where(stored_at: date.beginning_of_day..date.end_of_day).count
        end

        picked_up_data = days.map do |date|
          Package.where(picked_up_at: date.beginning_of_day..date.end_of_day).count
        end

        render json: {
          success: true,
          data: {
            dates: days.map { |d| d.strftime("%m-%d") },
            stored: stored_data,
            picked_up: picked_up_data
          }
        }
      end

      def recent_activities
        activities = OperationLog.includes(:user)
                                .order(created_at: :desc)
                                .limit(10)
                                .map do |log|
          {
            time: log.created_at.strftime("%Y-%m-%d %H:%M"),
            action: log.action,
            user: log.user&.name || "系统"
          }
        end

        render json: { success: true, data: activities }
      end

      private

      def calculate_today_revenue
        # 计算今日收入（如果有收费功能）
        # 这里返回模拟数据
        Package.where(picked_up_at: Time.current.beginning_of_day..Time.current.end_of_day).count * 2
      end
    end
  end
end
