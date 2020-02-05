class CreateProgrammeActivity
  attr_accessor :organisation_id, :fund_id

  def initialize(organisation_id:, fund_id:)
    self.organisation_id = organisation_id
    self.fund_id = fund_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    fund = Activity.find(fund_id)
    fund.activities << activity

    activity.wizard_status = "identifier"
    activity.level = :programme

    activity.funding_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.funding_organisation_reference = "GB-GOV-13"
    activity.funding_organisation_type = "10"

    activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.accountable_organisation_reference = "GB-GOV-13"
    activity.accountable_organisation_type = "10"

    activity.save(validate: false)
    activity
  end
end
