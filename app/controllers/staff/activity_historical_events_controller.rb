# frozen_string_literal: true

class Staff::ActivityHistoricalEventsController < Staff::BaseController
  include Secured

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity
    @activity = ActivityPresenter.new(activity)
    @historical_events = @activity
      .historical_events
      .includes([:user, :report])
      .group_by { |event|
        {reference: event.reference,
         user: event.user&.email,
         timestamp: event.created_at.strftime("%d %b %Y at %R"),}
      }
  end
end
