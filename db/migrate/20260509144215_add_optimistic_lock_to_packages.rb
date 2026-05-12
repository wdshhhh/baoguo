class AddOptimisticLockToPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :packages, :lock_version, :integer
  end
end
