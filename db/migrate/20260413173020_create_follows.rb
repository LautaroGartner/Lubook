class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :receiver,  null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.integer    :status,    null: false, default: 0

      t.timestamps
    end

    add_index :follows, [ :requester_id, :receiver_id ], unique: true
    add_index :follows, :status
    add_index :follows, [ :receiver_id, :status ]
  end
end
