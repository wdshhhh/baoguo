module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [ :create, :register ]

      def create
        user = User.find_by(phone: params[:phone])

        if user&.authenticate(params[:password])
          if user.disabled?
            return render_error("账号已被禁用", status: :forbidden)
          end

          user.update_login_info(request.remote_ip)
          OperationLog.log("user_login", user: user, request: request)

          render_json({
            token: user.generate_jwt,
            user: user_info(user)
          })
        else
          render_error("手机号或密码错误", status: :unauthorized)
        end
      end

      def register
        user_params = params.permit(:phone, :password, :password_confirmation, :name, :employee_number)

        # 验证手机号格式
        if !user_params[:phone] || !user_params[:phone].match?(/\A1[3-9]\d{9}\z/)
          return render_error("手机号格式不正确", status: :bad_request)
        end

        # 验证密码
        if !user_params[:password] || user_params[:password].length < 6
          return render_error("密码长度至少6位", status: :bad_request)
        end

        if user_params[:password] != user_params[:password_confirmation]
          return render_error("两次密码输入不一致", status: :bad_request)
        end

        # 检查手机号是否已存在
        if User.exists?(phone: user_params[:phone])
          return render_error("该手机号已注册", status: :conflict)
        end

        # 创建用户
        user = User.new(
          phone: user_params[:phone],
          password: user_params[:password],
          password_confirmation: user_params[:password_confirmation],
          name: user_params[:name] || "普通用户",
          employee_number: user_params[:employee_number],
          role: "customer",  # 默认为普通用户
          status: "enabled"
        )

        if user.save
          OperationLog.log("user_register", user: user, request: request)
          render_json({
            token: user.generate_jwt,
            user: user_info(user),
            message: "注册成功"
          })
        else
          render_error(user.errors.full_messages.join(", "), status: :bad_request)
        end
      end

      def destroy
        OperationLog.log("user_logout", user: current_user, request: request)
        render_json({ message: "退出登录成功" })
      end

      def current
        render_json(user_info(current_user))
      end

      private

      def user_info(user)
        {
          id: user.id,
          phone: user.phone,
          employee_number: user.employee_number,
          name: user.name,
          role: user.role,
          role_name: role_name(user.role),
          last_login_at: user.last_login_at
        }
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
