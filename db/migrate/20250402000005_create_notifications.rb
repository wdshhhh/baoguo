class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, comment: '接收用户'
      t.string :title, null: false, comment: '通知标题'
      t.text :content, null: false, comment: '通知内容'
      t.integer :notification_type, null: false, comment: '通知类型: 0-入库通知, 1-取件提醒, 2-滞留预警, 3-系统通知'
      t.integer :status, default: 0, null: false, comment: '状态: 0-未读, 1-已读'
      t.datetime :read_at, comment: '阅读时间'
      t.references :package, foreign_key: true, comment: '关联包裹'

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, :status
    add_index :notifications, :created_at
  end
end
