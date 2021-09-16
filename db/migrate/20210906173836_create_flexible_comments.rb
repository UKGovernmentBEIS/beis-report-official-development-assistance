class CreateFlexibleComments < ActiveRecord::Migration[6.1]
  def change
    create_table :flexible_comments, id: :uuid do |t|
      t.uuid :commentable_id
      t.string :commentable_type
      t.text :comment

      t.timestamps
    end
    add_index :flexible_comments, :commentable_id
    add_index :flexible_comments, :commentable_type
  end
end
