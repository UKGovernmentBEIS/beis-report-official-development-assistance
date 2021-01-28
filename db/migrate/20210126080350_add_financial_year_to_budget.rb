class AddFinancialYearToBudget < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :financial_year, :integer
  end
end
