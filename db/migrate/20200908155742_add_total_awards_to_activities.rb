class AddTotalAwardsToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :total_awards, :integer
  end
end
