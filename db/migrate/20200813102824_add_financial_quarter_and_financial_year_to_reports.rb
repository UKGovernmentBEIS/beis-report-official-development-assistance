class AddFinancialQuarterAndFinancialYearToReports < ActiveRecord::Migration[6.0]
  def change
    add_column :reports, :financial_quarter, :integer
    add_column :reports, :financial_year, :integer
  end
end
