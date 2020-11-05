require "rails_helper"
require "csv"
Rails.application.load_tasks

describe "invalid_activities.rake" do
  it "creates a csv file on tmp folder with a list of invalid activities in RODA" do
    activities = create_list(:project_activity, 5)
    activities.first.update_columns(gdi: nil, collaboration_type: nil)
    activities.last.update_columns(title: nil, programme_status: nil)

    run_task(task_name: "invalid_activities")
    invalid_activities_from_csv = CSV.read("tmp/invalid_activities.csv")

    expect(invalid_activities_from_csv.count).to eql(2)
    expect(invalid_activities_from_csv.first).to include(activities.first.roda_identifier_compound)
    expect(invalid_activities_from_csv.first).to include(activities.first.title)
    expect(invalid_activities_from_csv.first).to include(activities.first.organisation.name)
    expect(invalid_activities_from_csv.first).to include(activities.first.level)
    expect(invalid_activities_from_csv.first).to include(Rails.application.routes.url_helpers.organisation_activity_details_url(activities.first.organisation, activities.first.id, host: ENV["DOMAIN"]))
  end
end

def run_task(task_name:)
  Rake::Task[task_name].invoke
end
