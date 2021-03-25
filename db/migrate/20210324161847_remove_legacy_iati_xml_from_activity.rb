class RemoveLegacyIatiXmlFromActivity < ActiveRecord::Migration[6.0]
  def up
    remove_column :activities, :legacy_iati_xml
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
