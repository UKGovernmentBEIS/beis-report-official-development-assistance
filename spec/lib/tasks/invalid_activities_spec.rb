require "rails_helper"
require "csv"

RSpec.describe "rake invalid_activities" do
  it "creates a csv file on tmp folder with a list of invalid activities in RODA" do
    activities = create_list(:project_activity, 5)

    first_invalid_activity = activities.first.tap { |a| a.update_columns(gdi: nil, collaboration_type: nil) }
    second_invalid_activity = activities.last.tap { |a| a.update_columns(title: nil, programme_status: nil) }

    task.execute
    invalid_activities_from_csv = CSV.read("tmp/invalid_activities.csv")

    expect(invalid_activities_from_csv.count).to eql(2)

    aggregate_failures do
      first_invalid_activity_row = invalid_activities_from_csv.detect { |row| row.include?(first_invalid_activity.roda_identifier) }
      expect(first_invalid_activity_row).to include(first_invalid_activity.title)
      expect(first_invalid_activity_row).to include(first_invalid_activity.organisation.name)
      expect(first_invalid_activity_row).to include(first_invalid_activity.level)
      expect(first_invalid_activity_row).to include(Rails.application.routes.url_helpers.organisation_activity_details_url(first_invalid_activity.organisation, first_invalid_activity.id, host: ENV["DOMAIN"]))

      second_invalid_activity_row = invalid_activities_from_csv.detect { |row| row.include?(second_invalid_activity.roda_identifier) }
      expect(second_invalid_activity_row).to include(second_invalid_activity.title)
      expect(second_invalid_activity_row).to include(second_invalid_activity.organisation.name)
      expect(second_invalid_activity_row).to include(second_invalid_activity.level)
      expect(second_invalid_activity_row).to include(Rails.application.routes.url_helpers.organisation_activity_details_url(second_invalid_activity.organisation, second_invalid_activity.id, host: ENV["DOMAIN"]))
    end
  end
end
