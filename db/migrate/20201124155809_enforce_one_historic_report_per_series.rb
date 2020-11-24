class EnforceOneHistoricReportPerSeries < ActiveRecord::Migration[6.0]
  def change
    change_table :reports do |t|
      t.index [:fund_id, :organisation_id],
        where: "financial_quarter IS NULL OR financial_year IS NULL",
        unique: true,
        name: "enforce_one_historic_report_per_series"
    end
  end
end
