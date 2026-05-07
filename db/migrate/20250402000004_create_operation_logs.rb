class CreateOperationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :operation_logs do |t|
      t.references :user, foreign_key: true, comment: '操作用户'
      t.string :action, null: false, comment: '操作类型'
      t.string :resource_type, comment: '资源类型'
      t.integer :resource_id, comment: '资源ID'
      t.json :details, comment: '操作详情'
      t.string :ip_address, comment: 'IP地址'
      t.string :user_agent, comment: '用户代理'

      t.timestamps
    end

    add_index :operation_logs, :action
    add_index :operation_logs, :resource_type
    add_index :operation_logs, :created_at
  end
end
