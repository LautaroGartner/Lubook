class AddRepliesChatsAndNotifications < ActiveRecord::Migration[8.1]
  def change
    change_table :comments, bulk: true do |t|
      t.references :parent, foreign_key: { to_table: :comments }, null: true
    end

    add_index :comments, [ :post_id, :parent_id, :created_at ], name: "index_comments_on_post_parent_created_at"

    create_table :conversations do |t|
      t.datetime :last_message_at
      t.timestamps
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :conversation_participants, [ :conversation_id, :user_id ], unique: true

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :body, null: false
      t.timestamps
    end

    add_index :messages, [ :conversation_id, :created_at ]

    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :action, null: false
      t.references :notifiable, polymorphic: true, null: false
      t.datetime :read_at
      t.timestamps
    end

    add_index :notifications, [ :recipient_id, :read_at, :created_at ], name: "index_notifications_on_recipient_read_created"
  end
end
