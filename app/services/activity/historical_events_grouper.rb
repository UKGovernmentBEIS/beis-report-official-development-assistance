class Activity
  class HistoricalEventsGrouper
    def initialize(activity:)
      @activity = activity
    end

    def call
      activity
        .historical_events
        .includes([:user, :report])
        .order(created_at: :desc)
        .group_by { |event|
          {reference: event.reference,
           user: event.user&.email,
           timestamp: event.created_at.strftime("%d %b %Y at %R")}
        }
    end

    private

    attr_reader :activity
  end
end
