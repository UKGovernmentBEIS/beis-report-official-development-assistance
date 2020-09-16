class AddReportReferenceToBudgets < ActiveRecord::Migration[6.0]
  def change
    add_reference :budgets, :report, type: :uuid
  end
end
