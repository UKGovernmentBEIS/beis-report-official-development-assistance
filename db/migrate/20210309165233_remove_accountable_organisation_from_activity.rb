class RemoveAccountableOrganisationFromActivity < ActiveRecord::Migration[6.0]
  def up
    remove_column :activities, :accountable_organisation_name
    remove_column :activities, :accountable_organisation_reference
    remove_column :activities, :accountable_organisation_type
  end

  def down
    add_column :activities, :accountable_organisation_name, :string
    add_column :activities, :accountable_organisation_reference, :string
    add_column :activities, :accountable_organisation_type, :string

    service_owner = Organisation.find_by(service_owner: true)

    Activity.update_all(
      accountable_organisation_name: service_owner.name,
      accountable_organisation_reference: service_owner.iati_reference,
      accountable_organisation_type: service_owner.organisation_type
    )

    non_gov_orgs = Organisation.where.not(organisation_type: [10, 11])

    non_gov_orgs.each do |org|
      Activity
        .where(
          level: [:project, :third_party_project],
          extending_organisation_id: org.id
        )
        .update_all(
          accountable_organisation_name: org.name,
          accountable_organisation_reference: org.iati_reference,
          accountable_organisation_type: org.organisation_type
        )
    end
  end
end
