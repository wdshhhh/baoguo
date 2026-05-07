class CreateA2Packages < ActiveRecord::Migration[8.1]
  def change
    create_table :a2_packages do |t|
      t.string :addressee_name
      t.integer :telephone_number
      t.string :addressee_site
      t.timestamps
    end
  end
end
