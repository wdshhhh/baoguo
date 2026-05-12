class AddIndexesToPackages < ActiveRecord::Migration[8.1]
  def change
    # 复合索引：status + created_at
    add_index :packages, [:status, :created_at]
    
    # 复合索引：status + deleted_at
    add_index :packages, [:status, :deleted_at]
    
    # 收件人手机号索引
    add_index :packages, :recipient_phone
    
    # 运单号唯一索引（排除已删除的）
    add_index :packages, :tracking_number, unique: true, where: "deleted_at IS NULL"
    
    # 取件码唯一索引（排除已删除的）
    add_index :packages, :pickup_code, unique: true, where: "deleted_at IS NULL"
    
    # 外键约束
    add_foreign_key :packages, :users, column: :user_id, on_delete: :nullify
    add_foreign_key :packages, :users, column: :stored_by_id, on_delete: :nullify
    add_foreign_key :packages, :users, column: :picked_up_by_id, on_delete: :nullify
    
    # 用户表索引
    add_index :users, :phone, unique: true
    add_index :users, :role
    add_index :users, :status
    
    # 登录会话索引
    add_index :login_sessions, [:user_id, :expires_at]
    add_index :login_sessions, :refresh_token, unique: true
  end
end
