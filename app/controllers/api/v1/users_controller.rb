module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show, :update, :destroy, :reset_password, :enable, :disable ]

      # GET /api/v1/users
      # 用户列表（管理员专属）
      def index
        authorize User

        query = User.all.order(created_at: :desc)

        # 按角色筛选
        if params[:role].present?
          query = query.by_role(params[:role])
        end

        # 按状态筛选
        if params[:status].present?
          query = query.where(status: params[:status])
        end

        # 按注册时间范围筛选
        if params[:start_date].present?
          query = query.where("created_at >= ?", Date.parse(params[:start_date]).beginning_of_day)
        end

        if params[:end_date].present?
          query = query.where("created_at <= ?", Date.parse(params[:end_date]).end_of_day)
        end

        # 关键词搜索
        if params[:keyword].present?
          search_term = "%#{params[:keyword]}%"
          query = query.where("phone LIKE ? OR name LIKE ? OR employee_number LIKE ?", search_term, search_term, search_term)
        end

        users = query.page(@page).per(@per_page)

        render_json(
          users.map { |user| user_info(user) },
          meta: pagination_meta(users)
        )
      end

      # GET /api/v1/users/:id
      # 获取用户详情
      def show
        authorize @user
        render_json(user_detail_info(@user))
      end

      # POST /api/v1/users
      # 创建用户（管理员专属）
      def create
        authorize User

        user_params = params.require(:user).permit(:phone, :password, :password_confirmation, :name, :role, :employee_number)

        # 验证密码
        unless user_params[:password].present? && user_params[:password].length >= 6
          return render_error("密码长度至少6位", status: :bad_request)
        end

        unless user_params[:password] == user_params[:password_confirmation]
          return render_error("两次密码输入不一致", status: :bad_request)
        end

        # 验证角色
        unless User.roles.key?(user_params[:role])
          return render_error("无效的角色类型", status: :bad_request)
        end

        user = User.new(
          phone: user_params[:phone],
          password: user_params[:password],
          password_confirmation: user_params[:password_confirmation],
          name: user_params[:name] || "新用户",
          role: user_params[:role],
          employee_number: user_params[:employee_number],
          status: "enabled"
        )

        if user.save
          OperationLog.log("user_created", user: current_user, resource: user, request: request)
          render_json(user_info(user), status: :created)
        else
          render_error(user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      # PUT /api/v1/users/:id
      # 更新用户信息
      def update
        authorize @user

        user_params = params.require(:user).permit(:name, :employee_number)

        if @user.update(user_params)
          OperationLog.log("user_updated", user: current_user, resource: @user, request: request)
          render_json(user_info(@user))
        else
          render_error(@user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      # DELETE /api/v1/users/:id
      # 删除用户（软删除）
      def destroy
        authorize @user

        @user.update(status: :disabled)
        OperationLog.log("user_deleted", user: current_user, resource: @user, request: request)
        render_json({ message: "用户已禁用" })
      end

      # PUT /api/v1/users/:id/reset_password
      # 重置密码（管理员专属）
      def reset_password
        authorize @user, :reset_password?

        new_password = params[:password]

        unless new_password.present? && new_password.length >= 6
          return render_error("密码长度至少6位", status: :bad_request)
        end

        @user.password = new_password
        @user.password_confirmation = new_password

        if @user.save
          OperationLog.log("user_password_reset", user: current_user, resource: @user, request: request)
          render_json({ message: "密码重置成功" })
        else
          render_error(@user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      # PUT /api/v1/users/:id/enable
      # 启用用户
      def enable
        authorize @user, :enable?

        @user.update(status: :enabled)
        OperationLog.log("user_enabled", user: current_user, resource: @user, request: request)
        render_json({ message: "用户已启用" })
      end

      # PUT /api/v1/users/:id/disable
      # 禁用用户
      def disable
        authorize @user, :disable?

        @user.update(status: :disabled)
        OperationLog.log("user_disabled", user: current_user, resource: @user, request: request)
        render_json({ message: "用户已禁用" })
      end

      # PUT /api/v1/users/:id/update_role
      # 更新用户角色（管理员专属）
      def update_role
        authorize @user, :update_role?

        new_role = params[:role]

        unless User.roles.key?(new_role)
          return render_error("无效的角色类型", status: :bad_request)
        end

        @user.update(role: new_role)
        OperationLog.log("user_role_updated", user: current_user, resource: @user, request: request)
        render_json(user_info(@user))
      end

      # GET /api/v1/users/profile
      # 获取当前用户信息
      def profile
        render_json(user_detail_info(current_user))
      end

      # PUT /api/v1/users/update_profile
      # 更新当前用户信息
      def update_profile
        user_params = params.require(:user).permit(:name)

        if current_user.update(user_params)
          render_json(user_info(current_user))
        else
          render_error(current_user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      # PUT /api/v1/users/change_password
      # 当前用户修改密码
      def change_password
        current_password = params[:current_password]
        new_password = params[:new_password]
        confirm_password = params[:confirm_password]

        unless current_user.authenticate(current_password)
          return render_error("当前密码不正确", status: :bad_request)
        end

        unless new_password.present? && new_password.length >= 6
          return render_error("新密码长度至少6位", status: :bad_request)
        end

        unless new_password == confirm_password
          return render_error("两次密码输入不一致", status: :bad_request)
        end

        current_user.password = new_password
        current_user.password_confirmation = confirm_password

        if current_user.save
          OperationLog.log("user_self_password_changed", user: current_user, request: request)
          render_json({ message: "密码修改成功" })
        else
          render_error(current_user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_info(user)
        {
          id: user.id,
          phone: user.phone,
          name: user.name,
          role: user.role,
          role_name: role_name(user.role),
          status: user.status,
          status_name: user.status == "enabled" ? "启用" : "禁用",
          employee_number: user.employee_number,
          created_at: user.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          last_login_at: user.last_login_at&.strftime("%Y-%m-%d %H:%M:%S"),
          active_session_count: user.active_session_count
        }
      end

      def user_detail_info(user)
        info = user_info(user)
        info.merge!({
          last_login_ip: user.last_login_ip,
          updated_at: user.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        })
      end

      def role_name(role)
        {
          "customer" => "普通用户",
          "staff" => "驿站工作人员",
          "admin" => "系统管理员"
        }[role]
      end
    end
  end
end
