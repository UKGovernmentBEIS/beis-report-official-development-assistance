class RemoveStatusFromActivity < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :status
  end
end
