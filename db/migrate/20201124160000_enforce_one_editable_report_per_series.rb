class EnforceOneEditableReportPerSeries < ActiveRecord::Migration[6.0]
  def change
    change_table :reports do |t|
      t.index [:fund_id, :organisation_id],
        where: "state IN ('active', 'awaiting_changes')",
        unique: true,
        name: "enforce_one_editable_report_per_series"
    end
  end
end
