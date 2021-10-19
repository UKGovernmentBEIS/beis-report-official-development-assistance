class RemoveLegacyComments < ActiveRecord::Migration[6.1]
  def up
    drop_table :legacy_comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
