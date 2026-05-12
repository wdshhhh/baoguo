class CreateCourierCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :courier_companies do |t|
      t.string :name, null: false, limit: 50
      t.string :code, null: false, limit: 20
      t.string :logo_url, limit: 255
      t.string :contact_phone, limit: 20
      t.string :website, limit: 255
      t.text :description
      t.integer :status, default: 1, null: false
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end

    add_index :courier_companies, :name, unique: true
    add_index :courier_companies, :code, unique: true
    add_index :courier_companies, :status
  end
end