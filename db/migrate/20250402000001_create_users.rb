class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :phone, null: false, comment: '手机号'
      t.string :employee_number, comment: '工号'
      t.string :name, null: false, comment: '姓名'
      t.string :password_digest, null: false, comment: '密码摘要'
      t.integer :role, default: 0, null: false, comment: '角色: 0-普通用户, 1-驿站工作人员, 2-系统管理员'
      t.integer :status, default: 1, null: false, comment: '状态: 0-禁用, 1-启用'
      t.datetime :last_login_at, comment: '最后登录时间'
      t.string :last_login_ip, comment: '最后登录IP'
      t.datetime :deleted_at, comment: '软删除时间'

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :employee_number, unique: true
    add_index :users, :deleted_at
  end
end
