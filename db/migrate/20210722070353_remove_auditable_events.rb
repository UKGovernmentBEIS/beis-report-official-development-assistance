class RemoveAuditableEvents < ActiveRecord::Migration[6.1]
  def up
    drop_table :auditable_events
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
