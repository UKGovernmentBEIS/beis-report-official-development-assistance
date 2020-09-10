class AddTotalApplicationsToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :total_applications, :integer
  end
end
