module Api
  module V1
    class ExceptionManagementController < BaseController
      before_action :authenticate_user!

      # GET /api/v1/exceptions
      # 获取异常列表
      def index
        authorize PackageException
        begin
          exceptions = PackageException
            .includes(:package, :reported_by, :resolved_by)
            .order(created_at: :desc)
            .page(params[:page] || 1)
            .per(params[:per_page] || 10)

          # 过滤条件
          if params[:status].present?
            if params[:status] == "not_resolved"
              # 未解决状态：pending 和 processing
              exceptions = exceptions.where(status: [ :pending, :processing ])
            else
              exceptions = exceptions.where(status: params[:status])
            end
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
          authorize exception
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
        authorize PackageException
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
          authorize exception, :mark_as_processing?

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
          authorize exception, :resolve?

          # 验证处理方式
          handle_method = params[:handle_method]
          unless handle_method.present? && ExceptionLog.handle_methods.keys.include?(handle_method)
            return render_error("请选择处理方式", status: :bad_request)
          end

          # 验证处理结果
          result = params[:result]
          unless result.present?
            return render_error("请填写处理结果", status: :bad_request)
          end

          ActiveRecord::Base.transaction do
            # 更新异常状态
            exception.update!(
              status: :resolved,
              resolved_by: current_user,
              resolved_at: Time.current,
              solution: result
            )

            # 根据参数决定是否恢复包裹状态
            if params[:restore_package_status] == "true" && exception.package && exception.package.exception?
              exception.package.update!(status: :stored)
            end

            # 记录处理日志
            ExceptionLog.create!(
              package_exception: exception,
              handle_method: handle_method,
              result: result,
              handled_by: current_user
            )
          end

          OperationLog.log("exception_resolved", user: current_user, resource: exception, request: request)
          render_json(format_exception(exception))
        rescue ActiveRecord::RecordNotFound
          render_error("异常记录不存在", status: :not_found)
        rescue => e
          Rails.logger.error("解决异常失败: #{e.message}")
          render_error("解决异常失败: #{e.message}")
        end
      end

      # POST /api/v1/exceptions/batch_process
      # 批量处理异常
      def batch_process
        authorize PackageException, :batch_process?
        begin
          exception_ids = params[:ids]
          action = params[:action]

          unless exception_ids.present? && action.present?
            return render_error("请选择要处理的异常记录并指定操作")
          end

          # 验证只能处理待处理或处理中的异常
          exceptions = PackageException.where(id: exception_ids)
          invalid_exceptions = exceptions.where.not(status: [ :pending, :processing ])

          if invalid_exceptions.exists?
            return render_error("只能批量处理状态为'待处理'或'处理中'的异常")
          end

          # 创建批量操作日志
          batch_log = BatchOperationLog.create!(
            operation_type: action == "resolve" ? :batch_resolve : :batch_processing,
            total_count: exceptions.count,
            user: current_user
          )

          success_count = 0
          fail_count = 0
          fail_details = []

          case action
          when "mark_processing"
            exceptions.each do |exception|
              begin
                exception.update!(status: :processing, updated_at: Time.current)
                success_count += 1
              rescue => e
                fail_count += 1
                fail_details << { exception_id: exception.id, tracking_number: exception.package&.tracking_number, reason: e.message }
              end
            end
            OperationLog.log("exception_batch_processing", user: current_user, request: request)

          when "resolve"
            # 验证处理方式
            handle_method = params[:handle_method]
            unless handle_method.present? && ExceptionLog.handle_methods.keys.include?(handle_method)
              batch_log.update(status: :completed, completed_at: Time.current)
              return render_error("请选择处理方式", status: :bad_request)
            end

            # 验证处理结果
            result = params[:result]
            unless result.present?
              batch_log.update(status: :completed, completed_at: Time.current)
              return render_error("请填写处理结果", status: :bad_request)
            end

            restore_status = params[:restore_package_status] == "true"

            exceptions.each do |exception|
              begin
                ActiveRecord::Base.transaction do
                  exception.update!(
                    status: :resolved,
                    resolved_by: current_user,
                    resolved_at: Time.current,
                    solution: result
                  )

                  if restore_status && exception.package && exception.package.exception?
                    exception.package.update!(status: :stored)
                  end

                  # 记录处理日志
                  ExceptionLog.create!(
                    package_exception: exception,
                    handle_method: handle_method,
                    result: result,
                    handled_by: current_user,
                    batch_operation_log: batch_log
                  )
                end
                success_count += 1
              rescue => e
                fail_count += 1
                fail_details << { exception_id: exception.id, tracking_number: exception.package&.tracking_number, reason: e.message }
              end
            end
            OperationLog.log("exception_batch_resolved", user: current_user, request: request)

          else
            batch_log.update(status: :completed, completed_at: Time.current)
            return render_error("不支持的操作类型")
          end

          # 更新批量操作日志
          batch_log.complete(success_count, fail_count, fail_details.presence)

          # 返回处理结果
          response_data = {
            message: fail_count > 0 ? "批量操作部分完成" : "批量操作成功",
            operation_id: batch_log.operation_id,
            total_count: exceptions.count,
            success_count: success_count,
            fail_count: fail_count
          }
          response_data[:fail_details] = fail_details if fail_count > 0

          render_json(response_data)
        rescue => e
          Rails.logger.error("批量处理异常失败: #{e.message}")
          render_error("批量处理异常失败: #{e.message}")
        end
      end

      # DELETE /api/v1/exceptions/:id
      # 删除异常
      def destroy
        begin
          exception = PackageException.find(params[:id])
          authorize exception
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
