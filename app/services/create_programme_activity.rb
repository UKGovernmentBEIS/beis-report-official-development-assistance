class CreateProgrammeActivity
  attr_accessor :organisation_id, :fund_id

  def initialize(organisation_id:, fund_id:)
    self.organisation_id = organisation_id
    self.fund_id = fund_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    activity.reporting_organisation = activity.organisation

    fund = Activity.find(fund_id)
    fund.child_activities << activity

    activity.wizard_status = "blank"
    activity.level = :programme

    activity.funding_organisation_name = service_owner.name
    activity.funding_organisation_reference = service_owner.iati_reference
    activity.funding_organisation_type = service_owner.organisation_type

    activity.accountable_organisation_name = service_owner.name
    activity.accountable_organisation_reference = service_owner.iati_reference
    activity.accountable_organisation_type = service_owner.organisation_type

    activity.save!
    activity
  end

  def service_owner
    Organisation.find_by_service_owner(true)
  end
end
