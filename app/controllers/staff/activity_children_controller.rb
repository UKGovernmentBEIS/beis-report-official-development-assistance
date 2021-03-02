# frozen_string_literal: true

class Staff::ActivityChildrenController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @activities = @activity.child_activities.includes([:organisation, :parent]).order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }
  end

  def create
    parent_activity = Activity.find(params[:activity_id])
    delivery_partner_organisation = Organisation.find(params[:organisation_id])

    activity = Activity.new_child(
      parent_activity: parent_activity,
      delivery_partner_organisation: delivery_partner_organisation
    )

    authorize activity

    activity.save!

    activity.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(activity.id, activity.form_state)
  end
end
