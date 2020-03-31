class CreateFundActivity
  attr_accessor :organisation_id

  def initialize(organisation_id:)
    self.organisation_id = organisation_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    activity.reporting_organisation = activity.organisation

    activity.wizard_status = "blank"
    activity.level = :fund

    activity.funding_organisation_name = "HM Treasury"
    activity.funding_organisation_reference = "GB-GOV-2"
    activity.funding_organisation_type = "10"

    activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.accountable_organisation_reference = "GB-GOV-13"
    activity.accountable_organisation_type = "10"

    activity.extending_organisation = Organisation.find_by!(service_owner: true)

    activity.save(validate: false)
    activity
  end
end
