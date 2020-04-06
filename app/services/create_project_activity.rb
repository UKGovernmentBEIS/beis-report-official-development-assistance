class CreateProjectActivity
  attr_accessor :user, :organisation_id, :programme_id

  def initialize(user:, organisation_id:, programme_id:)
    self.organisation_id = organisation_id
    self.programme_id = programme_id
    self.user = user
  end

  def call
    service_owner = Organisation.find_by(service_owner: true)
    reporting_organisation = Organisation.find(organisation_id)

    activity = Activity.new
    activity.organisation = reporting_organisation
    activity.reporting_organisation_reference = reporting_organisation.iati_reference

    programme = Activity.find(programme_id)
    programme.child_activities << activity

    activity.wizard_status = "blank"
    activity.level = :project

    activity.funding_organisation_name = service_owner.name
    activity.funding_organisation_reference = service_owner.iati_reference
    activity.funding_organisation_type = service_owner.organisation_type

    activity.accountable_organisation_name = service_owner.name
    activity.accountable_organisation_reference = service_owner.iati_reference
    activity.accountable_organisation_type = service_owner.organisation_type

    activity.extending_organisation = reporting_organisation
    activity.save(validate: false)
    activity
  end
end
