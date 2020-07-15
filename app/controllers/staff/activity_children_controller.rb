# frozen_string_literal: true

class Staff::ActivityChildrenController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

    render "staff/activities/children"
  end
end
