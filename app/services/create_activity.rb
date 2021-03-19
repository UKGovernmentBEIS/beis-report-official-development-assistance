class CreateActivity
  attr_accessor :organisation_id

  def initialize(organisation_id:)
    self.organisation_id = organisation_id
  end

  def call
    activity = Activity.new
    activity.organisation = Organisation.find(organisation_id)
    activity.reporting_organisation = activity.organisation

    activity.form_state = "identifier"

    activity.save!
    activity
  end
end
