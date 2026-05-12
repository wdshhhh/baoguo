class CreateLoginSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :login_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :refresh_token
      t.datetime :expires_at
      t.string :ip_address

      t.timestamps
    end
  end
end
