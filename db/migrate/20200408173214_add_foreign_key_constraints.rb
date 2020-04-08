class AddForeignKeyConstraints < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :activities, :organisations, on_delete: :restrict

    # Already exists
    # add_foreign_key :activities, :activities, column: "activity_id", on_delete: :restrict

    # Already exists
    # add_foreign_key :activities, :organisations, column: "extending_organisation_id"

    # Column doesn't exist in this branch
    # add_foreign_key :activities, :organisations, column: "reporting_organisation_id"

    add_foreign_key :transactions, :activities, on_delete: :cascade
    add_foreign_key :budgets, :activities, on_delete: :cascade

    add_foreign_key :users, :organisations, on_delete: :restrict
  end
end
