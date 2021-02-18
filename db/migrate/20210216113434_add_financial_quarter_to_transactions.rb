class AddFinancialQuarterToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :financial_quarter, :integer
    add_column :transactions, :financial_year, :integer
  end
end
