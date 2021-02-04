class RemoveFlowFromActivities < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :flow
  end
end
