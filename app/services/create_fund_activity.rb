class CreateFundActivity
  attr_accessor :organisation_id

  def initialize(organisation_id:)
    self.organisation_id = organisation_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)

    activity.wizard_status = "identifier"
    activity.level = :fund
    activity.funding_organisation_name = "HM Treasury"
    activity.funding_organisation_reference = "GB-GOV-2"
    activity.funding_organisation_type = "10"
    activity.save(validate: false)
    activity
  end
end
