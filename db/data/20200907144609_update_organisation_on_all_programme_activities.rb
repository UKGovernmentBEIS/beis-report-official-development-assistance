class UpdateOrganisationOnAllProgrammeActivities < ActiveRecord::Migration[6.0]
  def up
    beis_organisation_id = Organisation.find_by(service_owner: true).id
    Activity.programmes.update_all(organisation_id: beis_organisation_id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
