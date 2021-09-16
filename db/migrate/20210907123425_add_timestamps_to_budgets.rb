class AddTimestampsToBudgets < ActiveRecord::Migration[6.1]
  def change
    add_column :budgets, :created_at, :datetime, precision: 6
    add_column :budgets, :updated_at, :datetime, precision: 6
  end
end
