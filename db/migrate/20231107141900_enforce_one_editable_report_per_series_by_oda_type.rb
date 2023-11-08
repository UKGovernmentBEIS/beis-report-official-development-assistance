class EnforceOneEditableReportPerSeriesByOdaType < ActiveRecord::Migration[6.1]
  def up
    remove_index :reports, name: "enforce_one_editable_report_per_series"

    add_index :reports, [:fund_id, :organisation_id, :is_oda],
      where: "state <> 'approved'",
      unique: true,
      name: "enforce_one_editable_report_per_series"
  end

  def down
    remove_index :reports, name: "enforce_one_editable_report_per_series"

    add_index :reports, [:fund_id, :organisation_id],
      where: "state <> 'approved'",
      unique: true,
      name: "enforce_one_editable_report_per_series"
  end
end
