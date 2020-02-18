class CreateProjectActivity
  attr_accessor :user, :organisation_id, :programme_id

  def initialize(user:, organisation_id:, programme_id:)
    self.organisation_id = organisation_id
    self.programme_id = programme_id
    self.user = user
  end

  def call
    reporting_organisation = Organisation.find(organisation_id)

    activity = Activity.new
    activity.organisation = reporting_organisation

    programme = Activity.find(programme_id)
    programme.activities << activity

    activity.wizard_status = "identifier"
    activity.level = :project

    activity.funding_organisation_name = reporting_organisation.name
    activity.funding_organisation_reference = reporting_organisation.iati_reference
    activity.funding_organisation_type = reporting_organisation.organisation_type

    activity.accountable_organisation_name = reporting_organisation.name
    activity.accountable_organisation_reference = reporting_organisation.iati_reference
    activity.accountable_organisation_type = reporting_organisation.organisation_type

    activity.extending_organisation = user.organisation
    activity.save(validate: false)
    activity
  end
end
