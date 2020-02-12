class CreateProjectActivity
  attr_accessor :organisation_id, :programme_id, :user

  def initialize(organisation_id:, programme_id:, user:)
    self.organisation_id = organisation_id
    self.programme_id = programme_id
    self.user = user
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    programme = Activity.find(programme_id)
    programme.activities << activity

    activity.wizard_status = "identifier"
    activity.level = :project

    activity.funding_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.funding_organisation_reference = "GB-GOV-13"
    activity.funding_organisation_type = "10"

    activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.accountable_organisation_reference = "GB-GOV-13"
    activity.accountable_organisation_type = "10"

    activity.extending_organisation = user.delivery_partner? ? user.organisation : nil

    activity.save(validate: false)
    activity
  end
end
