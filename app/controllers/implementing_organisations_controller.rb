class ImplementingOrganisationsController < BaseController
  def new
    @activity = Activity.find(params[:activity_id])
    authorize @activity
    @implementing_organisations = Organisation.active.sorted_by_name
    @implementing_organisation = Organisation.new
  end

  def create
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    org_participation = associate_implementing_organisation

    if org_participation.persisted?
      flash[:notice] = t("action.implementing_organisation.create.success")
      redirect_to organisation_activity_details_path(@activity.organisation, @activity)
    else
      flash[:error] = org_participation.errors.full_messages.first
      redirect_to new_activity_implementing_organisation_path(@activity)
    end
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
    org_participation = OrgParticipation.find_or_initialize_by(
      activity: @activity,
      organisation: implementing_organisation
    )

    org_participation.tap { |op| op.persisted? || op.save }
  end
end
