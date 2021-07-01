# frozen_string_literal: true

class Staff::ActivityHistoricalEventsController < Staff::BaseController
  include Secured

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity
    @activity = ActivityPresenter.new(activity)
  end
end
