class Staff::ProjectsController < Staff::ActivitiesController
  def create
    @project = CreateProjectActivity.new(user: current_user, organisation_id: params["organisation_id"], programme_id: params["programme_id"]).call
    authorize @project

    @project.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(@project.id, @project.wizard_status)
  end
end
