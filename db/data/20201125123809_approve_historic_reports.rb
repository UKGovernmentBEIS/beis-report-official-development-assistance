class ApproveHistoricReports < ActiveRecord::Migration[6.0]
  def up
    historic_imports = Report.where(financial_quarter: nil).or(Report.where(financial_year: nil))
    historic_imports.update_all(state: "approved")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
