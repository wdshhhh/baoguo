class CreatePackages < ActiveRecord::Migration[8.1]
  def change
    create_table :packages do |t|
      t.string :tracking_number, null: false, comment: '运单号'
      t.string :pickup_code, null: false, comment: '取件码'
      t.references :user, foreign_key: true, comment: '关联用户'
      t.string :recipient_name, null: false, comment: '收件人姓名'
      t.string :recipient_phone, null: false, comment: '收件人手机号'
      t.string :recipient_address, comment: '收件地址'
      t.string :storage_location, comment: '存放位置/货架号'
      t.integer :status, default: 0, null: false, comment: '状态: 0-待入库, 1-已入库, 2-已出库, 3-异常'
      t.integer :package_type, default: 0, comment: '包裹类型: 0-普通, 1-大件, 2-易碎, 3-贵重'
      t.decimal :weight, precision: 8, scale: 2, comment: '重量(kg)'
      t.text :remark, comment: '备注'
      t.datetime :stored_at, comment: '入库时间'
      t.datetime :picked_up_at, comment: '出库时间'
      t.references :stored_by, foreign_key: { to_table: :users }, comment: '入库操作人'
      t.references :picked_up_by, foreign_key: { to_table: :users }, comment: '出库操作人'
      t.datetime :deleted_at, comment: '软删除时间'

      t.timestamps
    end

    add_index :packages, :tracking_number, unique: true
    add_index :packages, :pickup_code
    add_index :packages, :recipient_phone
    add_index :packages, :status
    add_index :packages, :stored_at
    add_index :packages, :deleted_at
  end
end
