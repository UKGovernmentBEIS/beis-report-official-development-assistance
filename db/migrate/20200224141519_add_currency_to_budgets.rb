class AddCurrencyToBudgets < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :currency, :string
  end
end
