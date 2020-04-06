class RemoveTiedStatusFromActivities < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :tied_status, :string
  end
end
