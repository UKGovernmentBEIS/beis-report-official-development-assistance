class CreateFundActivity
  attr_accessor :organisation_id

  def initialize(organisation_id:)
    self.organisation_id = organisation_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    activity.reporting_organisation = activity.organisation
    activity.extending_organisation = service_owner

    activity.wizard_status = "blank"
    activity.level = :fund

    activity.funding_organisation_name = "HM Treasury"
    activity.funding_organisation_reference = "GB-GOV-2"
    activity.funding_organisation_type = "10"

    activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.accountable_organisation_reference = "GB-GOV-13"
    activity.accountable_organisation_type = "10"

    activity.save!
    activity
  end

  private

  def service_owner
    Organisation.find_by_service_owner(true)
  end
end
