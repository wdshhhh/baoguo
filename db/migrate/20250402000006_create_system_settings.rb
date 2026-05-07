class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.string :key, null: false, comment: '设置键'
      t.string :value, comment: '设置值'
      t.string :description, comment: '设置描述'
      t.integer :setting_type, default: 0, null: false, comment: '类型: 0-字符串, 1-数字, 2-布尔, 3-JSON'

      t.timestamps
    end

    add_index :system_settings, :key, unique: true
  end
end
