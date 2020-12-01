class RestrictReportStates < ActiveRecord::Migration[6.0]
  def change
    remove_index :reports,
      column: [:fund_id, :organisation_id],
      name: "enforce_one_editable_report_per_series"

    add_index :reports, [:fund_id, :organisation_id],
      where: "state NOT IN ('inactive', 'approved')",
      unique: true,
      name: "enforce_one_editable_report_per_series"
  end
end
