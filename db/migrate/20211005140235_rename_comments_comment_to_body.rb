class RenameCommentsCommentToBody < ActiveRecord::Migration[6.1]
  def change
    rename_column :comments, :comment, :body
  end
end
