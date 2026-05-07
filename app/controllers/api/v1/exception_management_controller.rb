module Api
  module V1
    class ExceptionManagementController < BaseController
      before_action :authenticate_user!
      before_action :authorize_staff!, except: [ :index, :show ]

      # GET /api/v1/exceptions
      # 获取异常列表
      def index
        begin
          exceptions = PackageException
            .includes(:package, :reported_by, :resolved_by)
            .order(created_at: :desc)
            .page(params[:page] || 1)
            .per(params[:per_page] || 10)

          # 过滤条件
          if params[:status].present?
            exceptions = exceptions.where(status: params[:status])
          end

          if params[:exception_type].present?
            exceptions = exceptions.where(exception_type: params[:exception_type])
          end

          if params[:search].present?
            search_term = "%#{params[:search]}%"
            exceptions = exceptions.joins(:package).where(
              "packages.tracking_number LIKE ? OR packages.recipient_phone LIKE ? OR packages.recipient_name LIKE ?",
              search_term, search_term, search_term
            )
          end

          render_json(
            exceptions.map { |exception| format_exception(exception) },
            meta: {
              total: exceptions.total_count,
              page: exceptions.current_page,
              per_page: exceptions.limit_value
            }
          )
        rescue => e
          Rails.logger.error("获取异常列表失败: #{e.message}")
          render_error("获取异常列表失败")
        end
      end

      # GET /api/v1/exceptions/:id
      # 获取异常详情
      def show
        begin
          exception = PackageException.find(params[:id])
          render_json(format_exception_detail(exception))
        rescue ActiveRecord::RecordNotFound
          render_error("异常记录不存在", status: :not_found)
        rescue => e
          Rails.logger.error("获取异常详情失败: #{e.message}")
          render_error("获取异常详情失败")
        end
      end

      # POST /api/v1/exceptions
      # 创建异常
      def create
        begin
          exception = PackageException.new(exception_params)
          exception.reported_by = current_user

          if exception.save
            # 自动将对应包裹标记为异常状态
            if exception.package
              exception.package.update(status: :exception)
            end

            OperationLog.log("exception_created", user: current_user, resource: exception, request: request)
            render_json(format_exception(exception), status: :created)
          else
            render_error("创建异常失败", errors: exception.errors.full_messages)
          end
        rescue => e
          Rails.logger.error("创建异常失败: #{e.message}")
          render_error("创建异常失败: #{e.message}")
        end
      end

      # POST /api/v1/exceptions/:id/process
      # 处理异常
      def mark_as_processing
        begin
          exception = PackageException.find(params[:id])

          if exception.update(
            status: :processing,
            solution: params[:solution].presence
          )
            OperationLog.log("exception_processed", user: current_user, resource: exception, request: request)
            render_json(format_exception(exception))
          else
            render_error("处理异常失败", errors: exception.errors.full_messages)
          end
        rescue ActiveRecord::RecordNotFound
          render_error("异常记录不存在", status: :not_found)
        rescue => e
          Rails.logger.error("处理异常失败: #{e.message}")
          render_error("处理异常失败: #{e.message}")
        end
      end

      # POST /api/v1/exceptions/:id/resolve
      # 解决异常
      def resolve
        begin
          exception = PackageException.find(params[:id])

          if exception.update(
            status: :resolved,
            resolved_by: current_user,
            resolved_at: Time.current,
            solution: params[:solution].presence
          )
            # 恢复包裹状态
            if exception.package && exception.package.exception?
              exception.package.update(status: :stored)
            end

            OperationLog.log("exception_resolved", user: current_user, resource: exception, request: request)
            render_json(format_exception(exception))
          else
            render_error("解决异常失败", errors: exception.errors.full_messages)
          end
        rescue ActiveRecord::RecordNotFound
          render_error("异常记录不存在", status: :not_found)
        rescue => e
          Rails.logger.error("解决异常失败: #{e.message}")
          render_error("解决异常失败: #{e.message}")
        end
      end

      # DELETE /api/v1/exceptions/:id
      # 删除异常
      def destroy
        begin
          exception = PackageException.find(params[:id])
          exception.destroy

          OperationLog.log("exception_deleted", user: current_user, resource: exception, request: request)
          render_json({ message: "异常删除成功" })
        rescue ActiveRecord::RecordNotFound
          render_error("异常记录不存在", status: :not_found)
        rescue => e
          Rails.logger.error("删除异常失败: #{e.message}")
          render_error("删除异常失败: #{e.message}")
        end
      end

      private

      def exception_params
        params.require(:exception).permit(
          :package_id,
          :exception_type,
          :description
        )
      end

      def format_exception(exception)
        {
          id: exception.id,
          package: {
            tracking_number: exception.package&.tracking_number,
            recipient_name: exception.package&.recipient_name,
            recipient_phone: exception.package&.recipient_phone,
            pickup_code: exception.package&.pickup_code
          },
          exception_type: exception.exception_type,
          status: exception.status,
          description: exception.description,
          solution: exception.solution,
          reported_by: {
            name: exception.reported_by&.name
          },
          resolved_by: {
            name: exception.resolved_by&.name
          },
          created_at: exception.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          updated_at: exception.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          resolved_at: exception.resolved_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      def format_exception_detail(exception)
        format_exception(exception).merge({
          package_details: {
            id: exception.package&.id,
            tracking_number: exception.package&.tracking_number,
            recipient_name: exception.package&.recipient_name,
            recipient_phone: exception.package&.recipient_phone,
            storage_location: exception.package&.storage_location,
            package_type: exception.package&.package_type,
            weight: exception.package&.weight,
            status: exception.package&.status
          }
        })
      end
    end
  end
end
