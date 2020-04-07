class RenameBudgetActivityIdToParentActivityId < ActiveRecord::Migration[6.0]
  def up
    add_column :budgets, :parent_activity_id, :uuid
    add_index :budgets, :parent_activity_id
    add_foreign_key :budgets, :activities, column: :parent_activity_id, on_delete: :cascade

    ActiveRecord::Base.transaction do
      Budget.all.each do |budget|
        budget.parent_activity = budget.activity
        budget.save!
      end
    end

    remove_column :budgets, :activity_id
  end

  def down
    add_column :budgets, :activity_id, :uuid
    add_index :budgets, :activity_id
    add_foreign_key :budgets, :activities, on_delete: :cascade

    ActiveRecord::Base.transaction do
      Budget.all.each do |budget|
        budget.activity = budget.parent_activity
        budget.save!
      end
    end

    remove_column :budgets, :parent_activity_id
  end
end
