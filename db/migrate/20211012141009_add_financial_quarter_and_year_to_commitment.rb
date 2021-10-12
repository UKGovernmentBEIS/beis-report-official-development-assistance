class AddFinancialQuarterAndYearToCommitment < ActiveRecord::Migration[6.1]
  def change
    add_column :commitments, :financial_quarter, :integer
    add_column :commitments, :financial_year, :integer
  end
end
