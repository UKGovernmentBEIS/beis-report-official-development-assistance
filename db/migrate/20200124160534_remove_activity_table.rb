class RemoveActivityTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :activities
  end
end
