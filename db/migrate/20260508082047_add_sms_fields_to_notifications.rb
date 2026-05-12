class AddSmsFieldsToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :recipient_phone, :string
    add_column :notifications, :send_status, :string
    add_column :notifications, :send_at, :datetime
  end
end
