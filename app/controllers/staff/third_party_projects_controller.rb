class Staff::ThirdPartyProjectsController < Staff::ActivitiesController
  def create
    @third_party_project = CreateThirdPartyProjectActivity.new(user: current_user, organisation_id: params["organisation_id"], project_id: params["project_id"]).call
    authorize @third_party_project

    @third_party_project.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(@third_party_project.id, @third_party_project.wizard_status)
  end
end
