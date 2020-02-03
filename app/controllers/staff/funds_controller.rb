# frozen_string_literal: true

class Staff::FundsController < Staff::ActivitiesController
  def create
    @activity = Activity.new
    @activity.organisation = Organisation.find(organisation_id)
    authorize @activity

    @activity.wizard_status = "identifier"
    @activity.level = :fund
    @activity.funding_organisation_name = "HM Treasury"
    @activity.funding_organisation_reference = "GB-GOV-2"
    @activity.funding_organisation_type = "10"
    @activity.save(validate: false)

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end
end
