class AddRolesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role, :string
    add_index :users, :role
  end
end
