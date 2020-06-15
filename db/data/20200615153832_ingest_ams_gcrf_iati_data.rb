class IngestAmsGcrfIatiData < ActiveRecord::Migration[6.0]
  def up
    IngestIatiActivities.new(
      delivery_partner: Organisation.find_by!(iati_reference: "GB-COH-03520281"),
      file_io: File.read("#{Rails.root}/vendor/data/iati_activity_data/ams/gcrf/real_and_complete_legacy_file.xml")
    ).call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
