class AddFundingTypeToBudget < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :funding_type, :integer
  end
end
