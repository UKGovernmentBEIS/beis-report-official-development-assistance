require "csv"

desc "Creates a csv file with a list of completed but invalid activities in RODA"
task invalid_activities: :environment do
  activities = Activity.where(form_state: "complete")
  invalid_activities_array = activities.reject { |activity| activity.valid? }

  CSV.open("tmp/invalid_activities.csv", "wb") do |csv|
    invalid_activities_array.each do |activity|
      activity_url = Rails.application.routes.url_helpers.organisation_activity_details_url(activity.organisation, activity, host: ENV["DOMAIN"])
      csv << [activity.organisation.name, activity.roda_identifier, activity.title, activity.level, activity_url]
    end
  end
end
