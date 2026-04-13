class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.text       :body, null: false, limit: 2000

      t.timestamps
    end

    add_index :comments, [ :post_id, :created_at ]
  end
end
