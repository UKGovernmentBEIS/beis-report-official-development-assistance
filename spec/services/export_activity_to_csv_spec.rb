require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { create(:project_activity) }

  describe "#call" do
    it "creates a CSV line representation of the Activity" do
      activity_presenter = ActivityPresenter.new(project)
      result = ExportActivityToCsv.new(activity: project).call

      expect(result).to eq([
        activity_presenter.identifier,
        activity_presenter.transparency_identifier,
        activity_presenter.sector,
        activity_presenter.title,
        activity_presenter.description,
        activity_presenter.status,
        activity_presenter.planned_start_date,
        activity_presenter.actual_start_date,
        activity_presenter.planned_end_date,
        activity_presenter.actual_end_date,
        activity_presenter.recipient_region,
        activity_presenter.recipient_country,
        activity_presenter.aid_type,
        activity_presenter.level,
        "https://#{ENV["DOMAIN"]}#{Rails.application.routes.url_helpers.organisation_activity_details_path(activity_presenter.organisation, activity_presenter)}",
      ].to_csv)
    end
  end
end
