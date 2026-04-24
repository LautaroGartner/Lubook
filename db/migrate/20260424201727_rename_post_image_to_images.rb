class RenamePostImageToImages < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = 'images'
      WHERE record_type = 'Post' AND name = 'image'
    SQL
  end

  def down
    # Safe only if each post has ≤1 image (true when coming from has_one_attached)
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = 'image'
      WHERE record_type = 'Post' AND name = 'images'
    SQL
  end
end
