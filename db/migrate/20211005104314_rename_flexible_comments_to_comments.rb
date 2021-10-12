class RenameFlexibleCommentsToComments < ActiveRecord::Migration[6.1]
  def change
    rename_table :flexible_comments, :comments
  end
end
