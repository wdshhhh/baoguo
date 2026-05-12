module Api
  module V1
    class PackagesController < BaseController
      skip_before_action :authenticate_user!, only: [ :search_by_phone_suffix ]
      before_action :set_package, only: [ :show, :update, :destroy, :store, :pick_up, :mark_exception ]

      def index
        packages = policy_scope(Package).search(search_params)
                          .recent
                          .page(@page)
                          .per(@per_page)

        render_json(packages.map { |p| package_info(p) }, meta: pagination_meta(packages))
      end

      def show
        authorize @package
        render_json(package_detail_info(@package))
      end

      def create
        authorize Package
        # 数据验证
        validation_errors = PackageValidator.validate_create_params(package_params)
        if validation_errors.any?
          return render_error("参数验证失败", errors: validation_errors)
        end

        package = Package.new(package_params)
        package.user = current_user  # 关联当前用户

        if package.save
          OperationLog.log("package_created", user: current_user, resource: package, request: request)
          render_json(package_info(package), status: :created)
        else
          # 将模型验证错误转换为字段级别的错误格式
          model_errors = {}
          package.errors.each do |field, message|
            model_errors[field] = Array(model_errors[field] || []) << message
          end
          render_error("创建包裹失败", errors: model_errors)
        end
      end

      def update
        authorize @package
        if @package.update(package_params)
          OperationLog.log("package_updated", user: current_user, resource: @package, request: request)
          render_json(package_info(@package))
        else
          render_error("更新包裹失败", errors: @package.errors.full_messages)
        end
      end

      def destroy
        authorize @package
        @package.soft_delete!
        OperationLog.log("package_deleted", user: current_user, resource: @package, request: request)
        render_json({ message: "删除成功" })
      end

      def store
        authorize @package, :store?
        @package.store!(current_user)
        OperationLog.log("package_stored", user: current_user, resource: @package, request: request)
        render_json(package_info(@package))
      rescue => e
        render_error(e.message)
      end

      def pick_up
        authorize @package, :pick_up?
        @package.pick_up!(current_user, params[:pickup_phone])
        OperationLog.log("package_picked_up", user: current_user, resource: @package, request: request)
        render_json(package_info(@package))
      rescue => e
        render_error(e.message)
      end

      def batch_store
        authorize Package, :batch_store?
        package_ids = params[:package_ids]
        return render_error("请选择要入库的包裹", status: :bad_request) unless package_ids.present? && package_ids.is_a?(Array)

        success_count = 0
        failed_count = 0
        failed_messages = []

        Package.transaction do
          package_ids.each do |id|
            package = Package.find_by(id: id)
            next unless package

            begin
              package.store!(current_user)
              OperationLog.log("package_stored", user: current_user, resource: package, request: request)
              success_count += 1
            rescue => e
              failed_count += 1
              failed_messages << "包裹 #{package.tracking_number}: #{e.message}"
            end
          end
        end

        render_json({
          success_count: success_count,
          failed_count: failed_count,
          messages: failed_messages
        })
      end

      def batch_pick_up
        authorize Package, :batch_pick_up?
        package_ids = params[:package_ids]
        pickup_phone = params[:pickup_phone]

        return render_error("请选择要出库的包裹", status: :bad_request) unless package_ids.present? && package_ids.is_a?(Array)
        return render_error("取件人手机号不能为空", status: :bad_request) unless pickup_phone.present?
        return render_error("手机号格式不正确", status: :bad_request) unless pickup_phone.match?(/\A1[3-9]\d{9}\z/)

        success_count = 0
        failed_count = 0
        failed_messages = []

        Package.transaction do
          package_ids.each do |id|
            package = Package.find_by(id: id)
            next unless package

            begin
              package.pick_up!(current_user, pickup_phone)
              OperationLog.log("package_picked_up", user: current_user, resource: package, request: request)
              success_count += 1
            rescue => e
              failed_count += 1
              failed_messages << "包裹 #{package.tracking_number}: #{e.message}"
            end
          end
        end

        render_json({
          success_count: success_count,
          failed_count: failed_count,
          messages: failed_messages
        })
      end

      def mark_exception
        authorize @package, :mark_exception?
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

      def search_by_phone_suffix
        suffix = params[:suffix]
        return render_error("请提供手机号后4位", status: :bad_request) unless suffix.present? && suffix.length == 4

        # 根据手机号后4位查询包裹
        packages = Package.where("recipient_phone LIKE ?", "%#{suffix}").order(stored_at: :desc)

        result = packages.map do |pkg|
          {
            id: pkg.id,
            tracking_number: pkg.tracking_number,
            courier_company: pkg.courier_company,
            status: pkg.status,
            stored_at: pkg.stored_at,
            picked_up_at: pkg.picked_up_at
          }
        end

        render_json(result)
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
          today_exception: Package.where(status: :exception, updated_at: today).count,
          pending_count: Package.pending.count,
          stored_count: Package.stored.count,
          exception_count: Package.exception.count,
          overdue_count: Package.overdue.count
        })
      end

      def weekly_stats
        # 获取近7天的数据（包含今天）
        result = []
        6.downto(0) do |days_ago|
          date = days_ago.days.ago.to_date
          start_time = date.beginning_of_day
          end_time = date.end_of_day

          inbound = Package.where(stored_at: start_time..end_time).count
          outbound = Package.where(picked_up_at: start_time..end_time).count

          result << {
            date: date.strftime("%Y-%m-%d"),
            inbound: inbound,
            outbound: outbound
          }
        end

        render_json(result)
      end

      def export
        packages = Package.search(search_params).order(created_at: :desc)

        case params[:type]
        when "csv"
          send_data generate_csv(packages),
                    filename: "packages_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                    type: "text/csv"
        when "excel"
          send_data generate_excel(packages),
                    filename: "packages_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
                    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        else
          render_error("不支持的导出格式", status: :bad_request)
        end
      rescue => e
        render_error("导出失败: #{e.message}")
      end

      def import
        return render_error("请选择Excel文件") unless params[:file].present?

        file = params[:file]
        temp_file = Tempfile.new([ "import", ".xlsx" ], encoding: "binary")
        temp_file.binmode
        temp_file.write(file.read)
        temp_file.close

        result = ExcelImportService.import(temp_file.path)

        if result[:success]
          OperationLog.log("package_import", user: current_user, details: "批量导入包裹：#{result[:message]}", request: request)
          render_json(result)
        else
          render_error(result[:message])
        end
      ensure
        temp_file&.unlink
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
          :per_page,
          :keyword
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
          created_at: package.created_at,
          sms_sent: package.notifications.by_type(:stored).where(send_status: "sent").exists?
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

      def generate_csv(packages)
        headers = [ "运单号", "收件人", "手机号", "地址", "快递公司", "取件码", "状态", "存放位置", "入库时间", "取件时间" ]

        CSV.generate(encoding: "UTF-8") do |csv|
          csv << headers

          packages.each do |package|
            csv << [
              package.tracking_number,
              package.recipient_name,
              package.recipient_phone,
              package.recipient_address,
              package.courier_company,
              package.pickup_code,
              status_name(package.status),
              package.storage_location,
              package.stored_at&.strftime("%Y-%m-%d %H:%M:%S"),
              package.picked_up_at&.strftime("%Y-%m-%d %H:%M:%S")
            ]
          end
        end
      end

      def generate_excel(packages)
        require "axlsx"

        Axlsx::Package.new do |p|
          p.workbook.add_worksheet(name: "包裹数据") do |sheet|
            sheet.add_row [ "运单号", "收件人", "手机号", "地址", "快递公司", "取件码", "状态", "存放位置", "入库时间", "取件时间" ]

            packages.each do |package|
              sheet.add_row [
                package.tracking_number,
                package.recipient_name,
                package.recipient_phone,
                package.recipient_address,
                package.courier_company,
                package.pickup_code,
                status_name(package.status),
                package.storage_location,
                package.stored_at&.strftime("%Y-%m-%d %H:%M:%S"),
                package.picked_up_at&.strftime("%Y-%m-%d %H:%M:%S")
              ]
            end

            # 设置列宽
            sheet.column_widths 15, 10, 12, 30, 12, 10, 8, 12, 18, 18
          end
        end.to_stream.read
      end
    end
  end
end
