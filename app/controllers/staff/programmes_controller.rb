# frozen_string_literal: true

class Staff::ProgrammesController < Staff::ActivitiesController
  def create
    @programme = CreateProgrammeActivity.new(organisation_id: organisation_id, fund_id: fund_id).call
    authorize @programme

    @programme.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(@programme.id, @programme.form_state)
  end
end
