class AddApprovedAtToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :approved_at, :datetime
  end
end
