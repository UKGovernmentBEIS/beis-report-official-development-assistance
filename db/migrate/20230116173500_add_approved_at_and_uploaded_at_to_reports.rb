class AddApprovedAtAndUploadedAtToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :approved_at, :datetime
    add_column :reports, :uploaded_at, :datetime
  end
end
