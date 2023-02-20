# frozen_string_literal: true

class ActivityChildrenController < BaseController
  def create
    parent_activity = Activity.find(params[:activity_id])
    partner_organisation = Organisation.find(params[:organisation_id])

    activity = Activity.new_child(
      parent_activity: parent_activity,
      partner_organisation: partner_organisation
    )

    authorize activity

    activity.generate_upfront_id

    session["activity-#{activity.id}"] = activity

    redirect_to activity_step_path(activity.id, activity.form_state)
  end
end
