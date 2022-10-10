class ActivityRedactionsController < BaseController
  include Secured

  def edit
    @activity = Activity.find(activity_id)
    authorize @activity, :redact_from_iati?
  end

  def update
    @activity = Activity.find(activity_id)
    authorize @activity, :redact_from_iati?

    @activity.update(publish_to_iati: activity_params["publish_to_iati"])
    record_historical_event(@activity)

    @activity.child_activities.each do |child_activity|
      child_activity.update(publish_to_iati: activity_params["publish_to_iati"])
      record_historical_event(child_activity)
    end

    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  private

  def activity_id
    params[:activity_id]
  end

  def activity_params
    params.require(:activity).permit(:publish_to_iati)
  end

  def record_historical_event(activity)
    reference = activity.publish_to_iati ? "Activity published to IATI" : "Activity redacted from IATI"
    HistoryRecorder.new(user: current_user).call(
      changes: {publish_to_iati: activity.saved_change_to_attribute(:publish_to_iati)},
      reference: reference,
      activity: activity,
      trackable: activity
    )
  end
end
