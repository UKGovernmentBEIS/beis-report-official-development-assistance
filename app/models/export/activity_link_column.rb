class Export::ActivityLinkColumn
  def initialize(activities:)
    @activities = activities
  end

  def headers
    ["Link to activity"]
  end

  def rows
    return [] if @activities.nil?

    @activities.map { |activity|
      link = Rails.application.routes.url_helpers.organisation_activity_details_url(activity.organisation_id, activity, host: ENV["DOMAIN"]).to_s
      [activity.id, link]
    }.to_h
  end
end
