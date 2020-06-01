class AddReportingOrgToActivitiesWhereMissing < ActiveRecord::Migration[6.0]
  def up
    activities = Activity.where(reporting_organisation: nil)
    service_owner = Organisation.find_by_service_owner(true)
    activities.each do |activity|
      creating_organisation = activity.organisation
      reporting_organisation = case activity.level
      when :fund
        creating_organisation
      when :programme
        creating_organisation
      when :project
        service_owner
      when :third_party_project
        service_owner
      end
      activity.reporting_organisation = reporting_organisation
      activity.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
