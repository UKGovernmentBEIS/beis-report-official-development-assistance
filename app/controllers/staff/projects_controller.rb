class Staff::ProjectsController < Staff::ActivitiesController
  def create
    @activity = CreateProjectActivity.new(user: current_user, organisation_id: params["organisation_id"], programme_id: params["programme_id"]).call
    authorize @activity

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end
end
