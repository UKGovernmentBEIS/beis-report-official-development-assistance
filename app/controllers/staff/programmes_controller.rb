# frozen_string_literal: true

class Staff::ProgrammesController < Staff::ActivitiesController
  def create
    @activity = CreateProgrammeActivity.new(organisation_id: organisation_id, fund_id: fund_id).call
    authorize @activity

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end
end
