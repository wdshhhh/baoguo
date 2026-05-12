class CreateExceptionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :exception_logs do |t|
      t.references :package_exception, null: false, foreign_key: true, comment: '关联异常记录'
      t.integer :handle_method, null: false, comment: '处理方式: 0-联系客户, 1-联系快递公司, 2-已找回, 3-已赔偿, 4-退回寄件方, 5-其他'
      t.text :result, null: false, comment: '处理结果'
      t.references :handled_by, null: false, foreign_key: { to_table: :users }, comment: '处理人'

      t.timestamps
    end

    add_index :exception_logs, :handle_method
  end
end
