class AddOutboundAtToPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :packages, :outbound_at, :datetime
  end
end
