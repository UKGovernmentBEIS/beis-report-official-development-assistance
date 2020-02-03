class CreateBudgets < ActiveRecord::Migration[6.0]
  def change
    create_table :budgets, id: :uuid do |t|
      t.references :activity, type: :uuid
      t.string :budget_type
      t.string :status
      t.date :period_start_date
      t.date :period_end_date
      t.decimal :value, precision: 13, scale: 2
    end
  end
end
