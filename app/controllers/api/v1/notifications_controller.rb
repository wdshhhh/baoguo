module Api
  module V1
    class NotificationsController < BaseController
      # GET /api/v1/notifications
      # 获取通知列表（当前用户）
      def index
        query = current_user.notifications.recent

        # 按类型筛选
        if params[:type].present?
          query = query.by_type(params[:type])
        end

        # 按状态筛选
        if params[:status].present?
          query = query.where(status: params[:status])
        end

        # 按发送状态筛选
        if params[:send_status].present?
          query = query.where(send_status: params[:send_status])
        end

        # 按手机号筛选
        if params[:phone].present?
          query = query.where("recipient_phone LIKE ?", "%#{params[:phone]}%")
        end

        notifications = query.page(@page).per(@per_page)

        render_json(
          notifications.map { |n| notification_info(n) },
          meta: pagination_meta(notifications)
        )
      end

      # GET /api/v1/notifications/:id
      # 获取通知详情
      def show
        notification = current_user.notifications.find(params[:id])
        render_json(notification_detail_info(notification))
      rescue ActiveRecord::RecordNotFound
        render_error("通知不存在", status: :not_found)
      end

      # POST /api/v1/notifications/:id/mark_read
      # 标记为已读
      def mark_read
        notification = current_user.notifications.find(params[:id])
        notification.mark_as_read!
        render_json(notification_info(notification))
      rescue ActiveRecord::RecordNotFound
        render_error("通知不存在", status: :not_found)
      end

      # POST /api/v1/notifications/mark_all_read
      # 标记所有为已读
      def mark_all_read
        Notification.mark_all_as_read_for_user(current_user.id)
        render_json({ message: "所有通知已标记为已读" })
      end

      # GET /api/v1/notifications/unread_count
      # 获取未读数量
      def unread_count
        count = Notification.unread_count_for_user(current_user.id)
        render_json({ unread_count: count })
      end

      # POST /api/v1/notifications/:id/retry
      # 重试发送通知
      def retry
        notification = Notification.find(params[:id])
        authorize notification, :retry?

        if notification.send_status == 'sent'
          return render_error("该通知已发送成功，无需重试", status: :bad_request)
        end

        notification.send_sms_notification
        render_json(notification_info(notification))
      rescue ActiveRecord::RecordNotFound
        render_error("通知不存在", status: :not_found)
      end

      private

      def notification_info(notification)
        {
          id: notification.id,
          title: notification.title,
          content: notification.content,
          notification_type: notification.notification_type,
          notification_type_name: notification_type_name(notification.notification_type),
          status: notification.status,
          status_name: notification.status == 'unread' ? '未读' : '已读',
          send_status: notification.send_status,
          send_status_name: send_status_name(notification.send_status),
          recipient_phone: notification.recipient_phone,
          package_info: notification.package.present? ? {
            tracking_number: notification.package.tracking_number,
            pickup_code: notification.package.pickup_code,
            recipient_name: notification.package.recipient_name
          } : nil,
          created_at: notification.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          read_at: notification.read_at&.strftime("%Y-%m-%d %H:%M:%S"),
          send_at: notification.send_at&.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      def notification_detail_info(notification)
        info = notification_info(notification)
        info.merge!({
          updated_at: notification.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          user_id: notification.user_id
        })
      end

      def notification_type_name(type)
        {
          'stored' => '包裹入库',
          'picked_up' => '包裹取件',
          'overdue' => '滞留提醒',
          'system' => '系统通知'
        }[type] || type
      end

      def send_status_name(status)
        {
          'pending' => '待发送',
          'sent' => '已发送',
          'failed' => '发送失败'
        }[status] || status
      end
    end
  end
end
