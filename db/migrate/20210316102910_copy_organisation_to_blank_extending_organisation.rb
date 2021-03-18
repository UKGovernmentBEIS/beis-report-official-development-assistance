class CopyOrganisationToBlankExtendingOrganisation < ActiveRecord::Migration[6.0]
  def up
    activities_without_extending_org = Activity
      .where(extending_organisation_id: nil)
      .where(level: [:project, :third_party_project])

    activities_without_extending_org.find_each do |activity|
      activity.update_column(:extending_organisation_id, activity.organisation_id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
