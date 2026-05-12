class AddPickupPhoneToPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :packages, :pickup_phone, :string
  end
end
