class AddUpdatedByToSystemSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :system_settings, :updated_by, :integer
  end
end
