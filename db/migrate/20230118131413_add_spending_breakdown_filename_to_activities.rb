class AddSpendingBreakdownFilenameToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :spending_breakdown_filename, :string
  end
end
