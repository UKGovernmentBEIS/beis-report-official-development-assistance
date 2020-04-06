class AddReportingOrgAssociationToActivity < ActiveRecord::Migration[6.0]
  def up
    add_reference :activities, :reporting_organisation, type: :uuid, foreign_key: {to_table: :organisations}

    ActiveRecord::Base.transaction do
      service_owner = Organisation.find_by_service_owner(true)

      Activity.all.each do |activity|
        organisation = activity.organisation
        activity.reporting_organisation = if organisation.is_government?
          service_owner
        else
          organisation
        end
        activity.save!
      end
    end

    remove_column :activities, :reporting_organisation_reference, :string
  end

  def down
    add_column :activities, :reporting_organisation_reference, :string

    ActiveRecord::Base.transaction do
      activities = Activity.where.not(reporting_organisation_id: nil)

      activities.each do |activity|
        activity.reporting_organisation_reference = activity.reporting_organisation.iati_reference
        activity.save!
      end
    end

    remove_reference :activities, :reporting_organisation, type: :uuid
  end
end
