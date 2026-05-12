class CreateShelves < ActiveRecord::Migration[7.1]
  def change
    create_table :shelves do |t|
      t.string :name, null: false, limit: 50
      t.string :location, limit: 100
      t.integer :capacity, null: false, default: 50
      t.text :description
      t.integer :status, default: 1, null: false
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end

    add_index :shelves, :name, unique: true
    add_index :shelves, :status
  end
end