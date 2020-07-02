class Staff::ActivityRedactionsController < Staff::BaseController
  include Secured

  def edit
    @activity = Activity.find(activity_id)
    authorize @activity, :redact_from_iati?
  end

  def update
    @activity = Activity.find(activity_id)
    authorize @activity, :redact_from_iati?

    @activity.update(publish_to_iati: activity_params["publish_to_iati"])
    @activity.child_activities.update(publish_to_iati: activity_params["publish_to_iati"])

    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  private

  def activity_id
    params[:activity_id]
  end

  def activity_params
    params.require(:activity).permit(:publish_to_iati)
  end
end
