class AddForeignKeyConstraintToPlannedDisbursements < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key "planned_disbursements", "activities", column: "parent_activity_id", on_delete: :cascade
  end
end
