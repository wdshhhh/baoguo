class CreatePackageExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :package_exceptions do |t|
      t.references :package, null: false, foreign_key: true, comment: '关联包裹'
      t.integer :exception_type, null: false, comment: '异常类型: 0-滞留, 1-破损, 2-错发, 3-丢失, 4-其他'
      t.text :description, null: false, comment: '异常描述'
      t.integer :status, default: 0, null: false, comment: '处理状态: 0-待处理, 1-处理中, 2-已解决'
      t.text :solution, comment: '解决方案'
      t.datetime :resolved_at, comment: '解决时间'
      t.references :reported_by, null: false, foreign_key: { to_table: :users }, comment: '上报人'
      t.references :resolved_by, foreign_key: { to_table: :users }, comment: '解决人'
      t.datetime :deleted_at, comment: '软删除时间'

      t.timestamps
    end

    add_index :package_exceptions, :exception_type
    add_index :package_exceptions, :status
    add_index :package_exceptions, :deleted_at
  end
end
