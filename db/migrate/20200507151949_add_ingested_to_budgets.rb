class AddIngestedToBudgets < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :ingested, :boolean, default: false
  end
end
