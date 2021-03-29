class FundingTypeBecomesBudgetType < ActiveRecord::Migration[6.0]
  def up
    remove_column :budgets, :budget_type
    add_column :budgets, :budget_type, :integer
    Budget.includes(:parent_activity).all.each do |budget|
      budget.budget_type = budget.parent_activity.source_fund_code
      budget.save(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
