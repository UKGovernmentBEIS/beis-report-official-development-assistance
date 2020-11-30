class PreventNullPlannedDisbursementScope < ActiveRecord::Migration[6.0]
  def change
    change_column_null :planned_disbursements, :parent_activity_id, false
    change_column_null :planned_disbursements, :financial_quarter, false
    change_column_null :planned_disbursements, :financial_year, false
  end
end
