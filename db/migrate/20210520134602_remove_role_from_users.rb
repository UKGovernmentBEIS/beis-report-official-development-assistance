class RemoveRoleFromUsers < ActiveRecord::Migration[6.1]
  def up
    remove_column :users, :role
  end

  def down
    add_column :users, :role, :string, index: true
    User.update_all(role: :administrator)
  end
end
