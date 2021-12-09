class Staff::ImplementingOrganisationsController < Staff::BaseController
  def new
    @activity = Activity.find(params[:activity_id])
    authorize @activity
    @implementing_organisations = Organisation.sorted_by_name
    @implementing_organisation = Organisation.new
  end

  def create
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    associate_implementing_organisation

    flash[:notice] = t("action.implementing_organisation.create.success")
    redirect_to organisation_activity_details_path(@activity.organisation, @activity)
  end

  def destroy
    @activity = Activity.find(params[:activity_id])
    authorize @activity, :edit?

    @activity.implementing_organisations.delete(implementing_organisation)

    flash[:notice] = t("action.implementing_organisation.delete.success")
    redirect_to organisation_activity_details_path(@activity.organisation, @activity)
  end

  private

  def implementing_organisation
    @implementing_organisation ||= Organisation
      .find(params.require(:implementing_organisation)
      .fetch(:organisation_id))
  end

  def associate_implementing_organisation
    return if @activity.implementing_organisations.include?(implementing_organisation)

    @activity.implementing_organisations << implementing_organisation
  end
end
