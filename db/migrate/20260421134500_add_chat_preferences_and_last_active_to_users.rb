class AddChatPreferencesAndLastActiveToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :share_last_seen, default: true, null: false
      t.boolean :share_read_receipts, default: true, null: false
      t.datetime :last_active_at
    end
  end
end
