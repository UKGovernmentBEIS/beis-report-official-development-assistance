class AddLegacyIatiXmlToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :legacy_iati_xml, :string
  end
end
