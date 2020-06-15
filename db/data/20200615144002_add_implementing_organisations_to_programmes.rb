class AddImplementingOrganisationsToProgrammes < ActiveRecord::Migration[6.0]
  def up
    programmes = Activity.programme
    programmes.each do |programme|
      next if programme.implementing_organisations.present?
      next unless programme.extending_organisation_id
      extending_organisation = Organisation.find(programme.extending_organisation_id)
      implementing_organisation = ImplementingOrganisation.new(name: extending_organisation.name,
                                                               organisation_type: extending_organisation.organisation_type,
                                                               reference: extending_organisation.iati_reference,
                                                               activity_id: programme.id)
      implementing_organisation.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
