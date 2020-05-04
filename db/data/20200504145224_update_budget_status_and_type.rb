class UpdateBudgetStatusAndType < ActiveRecord::Migration[6.0]
  def up
    budgets = Budget.all
    budgets.each do |budget|
      status = budget.status == "indicative" ? "1" : "2"
      type = budget.budget_type == "original" ? "1" : "2"
      budget.update(status: status, budget_type: type)
      budget.save!
    end
  end

  def down
    budgets = Budget.all
    budgets.each do |budget|
      status = budget.status == "1" ? "indicative" : "committed"
      type = budget.budget_type == "1" ? "original" : "updated"
      budget.update(status: status, budget_type: type)
      budget.save!
    end
  end
end
