# frozen_string_literal: true

class Staff::ProjectsController < Staff::ActivitiesController
  def create
    @activity = CreateProjectActivity.new(organisation_id: organisation_id, programme_id: programme_id).call
    authorize @activity

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end

  def programme_id
    params[:programme_id]
  end
end
