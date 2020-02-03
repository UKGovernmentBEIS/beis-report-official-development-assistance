# frozen_string_literal: true

class Staff::ProgrammesController < Staff::ActivitiesController
  def create
    @activity = Activity.new
    @activity.organisation = Organisation.find(organisation_id)
    fund = Activity.find(fund_id)
    fund.activities << @activity
    authorize @activity

    @activity.wizard_status = "identifier"
    @activity.level = :programme
    @activity.save(validate: false)

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end
end
