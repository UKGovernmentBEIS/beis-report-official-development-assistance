class IngestUksaIatiData < ActiveRecord::Migration[6.0]
  def up
    IngestIatiActivities.new(
      delivery_partner: Organisation.find_by!(iati_reference: "GB-GOV-EA31"),
      file_io: File.read("#{Rails.root}/spec/fixtures/activities/uksa/real_and_complete_legacy_file.xml")
    ).call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
