class ReplaceTransferDatesWithFinancialYearAndQuarter < ActiveRecord::Migration[6.0]
  def change
    remove_column :transfers, :date
    add_column :transfers, :financial_year, :integer
    add_column :transfers, :financial_quarter, :integer
  end
end
