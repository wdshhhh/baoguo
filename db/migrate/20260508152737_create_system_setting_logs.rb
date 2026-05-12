class CreateSystemSettingLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_setting_logs do |t|
      t.string :key
      t.text :old_value
      t.text :new_value
      t.integer :changed_by
      t.boolean :reset, default: false

      t.timestamps
    end
  end
end
