class ChangeSubmissionsToReports < ActiveRecord::Migration[5.0]
  def change
    rename_table :submissions, :reports
    rename_column :transactions, :submission_id, :report_id
  end
end
