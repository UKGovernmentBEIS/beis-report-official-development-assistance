class RemoveInactiveStateFromReportsConstraint < ActiveRecord::Migration[6.1]
  def change
    remove_index :reports,
      column: [:fund_id, :organisation_id],
      name: "enforce_one_editable_report_per_series"

    add_index :reports, [:fund_id, :organisation_id],
      where: "state <> 'approved'",
      unique: true,
      name: "enforce_one_editable_report_per_series"
  end
end
