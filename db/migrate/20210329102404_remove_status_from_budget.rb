class RemoveStatusFromBudget < ActiveRecord::Migration[6.0]
  def up
    remove_column :budgets, :status
  end

  def down
    add_column :budgets, :status, :string
  end
end
