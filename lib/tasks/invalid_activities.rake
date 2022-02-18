require "csv"
require "set"

namespace :activities do
  desc "Creates a csv file with activities that fail validation and why"
  task invalid: :environment do
    def error_strings(errors)
      errors.errors.map { |x| "#{x.attribute}: #{x.message}" }
    end

    domain = "https://report-official-development-assistance.service.gov.uk/" # ENV["DOMAIN"]
    error_list = Set[]
    activities = Activity.all
    invalid_activities_array = activities.reject(&:valid?)
    activities.each do |activity|
      error_list.merge(error_strings(activity))
    end

    CSV.open("tmp/invalid_activities.csv", "wb") do |csv|
      invalid_activities_array.each do |activity|
        activity_url = Rails.application.routes.url_helpers.organisation_activity_details_url(activity.organisation, activity, host: domain)
        errors = error_strings(activity)
        matched_errors = error_list.map { |x| errors.include?(x) ? x : "" }
        csv << [activity.organisation.name, activity.roda_identifier, activity.title, activity.level, activity_url] + matched_errors
      end
    end
  end
end
