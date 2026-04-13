class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :display_name, limit: 80
      t.text   :bio,          limit: 500
      t.string :location,     limit: 80

      t.timestamps
    end
  end
end
