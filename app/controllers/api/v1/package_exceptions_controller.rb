module Api
  module V1
    class PackageExceptionsController < BaseController
      before_action :set_package_exception, only: [ :show, :update, :destroy, :mark_processing, :resolve ]
      before_action :authorize_staff!, only: [ :create, :update, :destroy, :mark_processing, :resolve ]

      def index
        package_exceptions = PackageException.search(search_params)
                                          .recent
                                          .page(@page)
                                          .per(@per_page)

        render_json(package_exceptions.map { |pe| package_exception_info(pe) }, meta: pagination_meta(package_exceptions))
      end

      def show
        render_json(package_exception_detail_info(@package_exception))
      end

      def create
        package_exception = PackageException.new(package_exception_params)
        package_exception.reported_by = current_user

        if package_exception.save
          OperationLog.log("package_exception_created", user: current_user, resource: package_exception, request: request)
          render_json(package_exception_info(package_exception), status: :created)
        else
          render_error("创建异常记录失败", errors: package_exception.errors.full_messages)
        end
      end

      def update
        if @package_exception.update(package_exception_params)
          OperationLog.log("package_exception_updated", user: current_user, resource: @package_exception, request: request)
          render_json(package_exception_info(@package_exception))
        else
          render_error("更新异常记录失败", errors: @package_exception.errors.full_messages)
        end
      end

      def destroy
        @package_exception.destroy
        OperationLog.log("package_exception_deleted", user: current_user, resource: @package_exception, request: request)
        render_json({ message: "异常记录删除成功" })
      end

      def mark_processing
        begin
          # 简化参数处理
          resolution = params[:resolution] || params[:solution] || ""

          # 简化更新逻辑
          if @package_exception.update(
            status: :processing,
            solution: resolution.present? ? resolution : nil
          )
            OperationLog.log("package_exception_processed", user: current_user, resource: @package_exception, request: request)
            render_json(package_exception_info(@package_exception))
          else
            render_error("处理异常失败", errors: @package_exception.errors.full_messages)
          end
        rescue => e
          Rails.logger.error("处理异常失败: #{e.message}")
          render_error("处理异常失败: #{e.message}")
        end
      end

      def resolve
        begin
          # 简化参数处理
          resolution = params[:resolution] || params[:solution] || ""

          # 简化更新逻辑
          if @package_exception.update(
            status: :resolved,
            resolved_by: current_user,
            resolved_at: Time.current,
            solution: resolution.present? ? resolution : nil
          )
            # 简化包裹状态更新
            if @package_exception.package && @package_exception.package.exception?
              @package_exception.package.update(status: :stored)
            end

            OperationLog.log("package_exception_resolved", user: current_user, resource: @package_exception, request: request)
            render_json(package_exception_info(@package_exception))
          else
            render_error("解决异常失败", errors: @package_exception.errors.full_messages)
          end
        rescue => e
          Rails.logger.error("解决异常失败: #{e.message}")
          render_error("解决异常失败: #{e.message}")
        end
      end

      private

      def set_package_exception
        @package_exception = PackageException.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("异常记录不存在", status: :not_found)
      end

      def package_exception_params
        params.require(:package_exception).permit(
          :package_id,
          :exception_type,
          :description,
          :status
        )
      end

      def search_params
        params.permit(
          :search,
          :exception_type,
          :status,
          :package_tracking_number,
          :recipient_phone,
          :page,
          :per_page
        )
      end

      def package_exception_info(package_exception)
        {
          id: package_exception.id,
          package: {
            tracking_number: package_exception.package&.tracking_number,
            recipient_name: package_exception.package&.recipient_name,
            recipient_phone: package_exception.package&.recipient_phone,
            pickup_code: package_exception.package&.pickup_code
          },
          exception_type: package_exception.exception_type,
          status: package_exception.status,
          description: package_exception.description,
          solution: package_exception.solution,
          reported_by: {
            name: package_exception.reported_by&.name
          },
          resolved_by: {
            name: package_exception.resolved_by&.name
          },
          created_at: package_exception.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          updated_at: package_exception.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          resolved_at: package_exception.resolved_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      def package_exception_detail_info(package_exception)
        package_exception_info(package_exception).merge({
          package_details: {
            id: package_exception.package&.id,
            tracking_number: package_exception.package&.tracking_number,
            recipient_name: package_exception.package&.recipient_name,
            recipient_phone: package_exception.package&.recipient_phone,
            storage_location: package_exception.package&.storage_location,
            package_type: package_exception.package&.package_type,
            weight: package_exception.package&.weight,
            status: package_exception.package&.status
          },
          resolution_details: package_exception.resolution_details,
          resolved_at: package_exception.resolved_at&.strftime("%Y-%m-%d %H:%M:%S"),
          processed_at: package_exception.processed_at&.strftime("%Y-%m-%d %H:%M:%S")
        })
      end
    end
  end
end
