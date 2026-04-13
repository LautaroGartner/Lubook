class AddMissingIndexesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token,       unique: true
    add_index :users, "LOWER(username)",   unique: true, name: "index_users_on_lower_username"
  end
end
