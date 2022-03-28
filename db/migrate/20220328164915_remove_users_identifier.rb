class RemoveUsersIdentifier < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :identifier, :string, index: true
  end
end
