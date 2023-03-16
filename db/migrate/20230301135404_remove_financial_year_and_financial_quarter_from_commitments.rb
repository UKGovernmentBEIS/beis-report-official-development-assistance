class RemoveFinancialYearAndFinancialQuarterFromCommitments < ActiveRecord::Migration[6.1]
  def change
    remove_columns :commitments, :financial_year, :financial_quarter
  end
end
