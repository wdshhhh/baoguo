module Api
  module V1
    class PackagesController < BaseController
      before_action :set_package, only: [ :show, :update, :destroy, :store, :pick_up, :mark_exception ]
      before_action :authorize_staff!, only: [ :create, :update, :destroy, :store, :pick_up, :mark_exception ]

      def index
        packages = Package.search(search_params)
                          .recent
                          .page(@page)
                          .per(@per_page)

        render_json(packages.map { |p| package_info(p) }, meta: pagination_meta(packages))
      end

      def show
        render_json(package_detail_info(@package))
      end

      def create
        # 数据验证
        validation_errors = PackageValidator.validate_create_params(package_params)
        if validation_errors.any?
          return render_error("参数验证失败", errors: validation_errors)
        end
        
        package = Package.new(package_params)

        if package.save
          OperationLog.log("package_created", user: current_user, resource: package, request: request)
          render_json(package_info(package), status: :created)
        else
          render_error("创建包裹失败", errors: package.errors.full_messages)
        end
      end

      def update
        if @package.update(package_params)
          OperationLog.log("package_updated", user: current_user, resource: @package, request: request)
          render_json(package_info(@package))
        else
          render_error("更新包裹失败", errors: @package.errors.full_messages)
        end
      end

      def destroy
        @package.destroy
        OperationLog.log("package_deleted", user: current_user, resource: @package, request: request)
        render_json({ message: "删除成功" })
      end

      def store
        @package.store!(current_user)
        OperationLog.log("package_stored", user: current_user, resource: @package, request: request)
        render_json(package_info(@package))
      rescue => e
        render_error(e.message)
      end

      def pick_up
        @package.pick_up!(current_user)
        OperationLog.log("package_picked_up", user: current_user, resource: @package, request: request)
        render_json(package_info(@package))
      rescue => e
        render_error(e.message)
      end

      def mark_exception
        @package.mark_exception!(
          params[:exception_type],
          params[:description],
          current_user
        )
        OperationLog.log("package_exception_marked", user: current_user, resource: @package, request: request)
        render_json(package_info(@package))
      rescue => e
        render_error(e.message)
      end

      def search_by_code
        package = Package.find_by(pickup_code: params[:code])

        if package
          render_json(package_detail_info(package))
        else
          render_error("取件码不存在", status: :not_found)
        end
      end

      def statistics
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        stats = Package.statistics_by_date(start_date, end_date)

        render_json({
          summary: {
            total: stats[:total],
            stored: stats[:stored],
            picked_up: stats[:picked_up],
            exception: stats[:exception],
            pending: stats[:pending]
          },
          by_date: stats[:by_date],
          by_status: stats[:by_status]
        })
      end

      def today_overview
        today = Time.current.beginning_of_day..Time.current.end_of_day

        render_json({
          today_stored: Package.where(stored_at: today).count,
          today_picked_up: Package.where(picked_up_at: today).count,
          pending_count: Package.pending.count,
          stored_count: Package.stored.count,
          exception_count: Package.exception.count,
          overdue_count: Package.overdue.count
        })
      end

      def export
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today
        statuses = params[:statuses] ? params[:statuses].split(",") : [ "stored", "picked_up" ]

        packages = Package.where(status: statuses)
                          .where(stored_at: start_date.beginning_of_day..end_date.end_of_day)
                          .order(stored_at: :desc)

        case params[:type]
        when "csv"
          send_data generate_csv(packages, params[:fields]),
                    filename: "packages_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                    type: "text/csv"
        when "excel"
          send_data generate_excel(packages, params[:fields]),
                    filename: "packages_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
                    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        else
          render_error("不支持的导出格式", status: :bad_request)
        end
      rescue => e
        render_error("导出失败: #{e.message}")
      end

      private

      def set_package
        @package = Package.find(params[:id])
      end

      def package_params
        params.permit(
          :tracking_number,
          :recipient_name,
          :recipient_phone,
          :recipient_address,
          :storage_location,
          :package_type,
          :weight,
          :remark,
          :user_id
        )
      end

      def search_params
        params.permit(
          :tracking_number,
          :recipient_phone,
          :pickup_code,
          :status,
          :recipient_name,
          :storage_location,
          :start_date,
          :end_date,
          :page,
          :per_page
        )
      end

      def authorize_staff!
        unless current_user.staff? || current_user.admin?
          render_forbidden("只有工作人员可以执行此操作")
        end
      end

      def package_info(package)
        {
          id: package.id,
          tracking_number: package.tracking_number,
          pickup_code: package.pickup_code,
          recipient_name: package.recipient_name,
          recipient_phone: package.recipient_phone,
          storage_location: package.storage_location,
          status: package.status,
          status_name: status_name(package.status),
          package_type: package.package_type,
          weight: package.weight,
          stored_at: package.stored_at,
          picked_up_at: package.picked_up_at,
          created_at: package.created_at
        }
      end

      def package_detail_info(package)
        info = package_info(package)
        info.merge!({
          recipient_address: package.recipient_address,
          remark: package.remark,
          stored_by: package.stored_by&.name,
          picked_up_by: package.picked_up_by&.name,
          storage_duration: package.storage_duration,
          overdue: package.overdue?,
          exceptions: package.package_exceptions.map { |e| exception_info(e) }
        })
      end

      def exception_info(exception)
        {
          id: exception.id,
          type: exception.exception_type,
          type_name: exception_type_name(exception.exception_type),
          description: exception.description,
          status: exception.status,
          reported_by: exception.reported_by.name,
          created_at: exception.created_at
        }
      end

      def status_name(status)
        {
          "pending" => "待入库",
          "stored" => "已入库",
          "picked_up" => "已出库",
          "exception" => "异常"
        }[status]
      end

      def exception_type_name(type)
        {
          "overdue" => "滞留",
          "damaged" => "破损",
          "wrong_delivery" => "错发",
          "lost" => "丢失",
          "other" => "其他"
        }[type]
      end

      def generate_csv(packages, fields_param)
        fields = fields_param ? fields_param.split(",") : [ "tracking_number", "recipient_name", "recipient_phone", "pickup_code", "status", "stored_at", "picked_up_at" ]

        CSV.generate do |csv|
          # 表头
          headers = fields.map do |field|
            case field
            when "tracking_number" then "运单号"
            when "recipient_name" then "收件人"
            when "recipient_phone" then "手机号"
            when "pickup_code" then "取件码"
            when "status" then "状态"
            when "stored_at" then "入库时间"
            when "picked_up_at" then "取件时间"
            when "storage_location" then "存储位置"
            else field
            end
          end
          csv << headers

          # 数据行
          packages.each do |package|
            row = fields.map do |field|
              case field
              when "tracking_number" then package.tracking_number
              when "recipient_name" then package.recipient_name
              when "recipient_phone" then package.recipient_phone
              when "pickup_code" then package.pickup_code
              when "status" then status_name(package.status)
              when "stored_at" then package.stored_at&.strftime("%Y-%m-%d %H:%M:%S")
              when "picked_up_at" then package.picked_up_at&.strftime("%Y-%m-%d %H:%M:%S")
              when "storage_location" then package.storage_location
              else package.send(field) rescue ""
              end
            end
            csv << row
          end
        end
      end

      def generate_excel(packages, fields_param)
        # 使用简单的CSV格式作为Excel导出（实际项目中可以使用axlsx等gem）
        generate_csv(packages, fields_param)
      end
    end
  end
end
