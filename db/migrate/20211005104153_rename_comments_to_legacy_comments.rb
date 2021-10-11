class RenameCommentsToLegacyComments < ActiveRecord::Migration[6.1]
  def change
    rename_table :comments, :legacy_comments
  end
end
