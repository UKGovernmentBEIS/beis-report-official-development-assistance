class ReportStatesAreStrings < ActiveRecord::Migration[6.0]
  def up
    Report.update_all state: "inactive"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
