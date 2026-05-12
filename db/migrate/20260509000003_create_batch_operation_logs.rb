class CreateBatchOperationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :batch_operation_logs do |t|
      t.string :operation_id, null: false, comment: '批量操作ID'
      t.integer :operation_type, null: false, comment: '操作类型: 0-批量标记处理中, 1-批量解决'
      t.integer :status, null: false, default: 0, comment: '操作状态: 0-待执行, 1-处理中, 2-完成, 3-部分失败'
      t.integer :total_count, null: false, comment: '总数量'
      t.integer :current_count, default: 0, comment: '当前处理数量'
      t.integer :success_count, default: 0, comment: '成功数量'
      t.integer :fail_count, default: 0, comment: '失败数量'
      t.text :fail_details, comment: '失败详情'
      t.references :user, null: false, foreign_key: true, comment: '操作人'
      t.datetime :completed_at, comment: '完成时间'

      t.timestamps
    end

    add_index :batch_operation_logs, :operation_id, unique: true
    add_index :batch_operation_logs, :operation_type
    add_index :batch_operation_logs, :status
  end
end
