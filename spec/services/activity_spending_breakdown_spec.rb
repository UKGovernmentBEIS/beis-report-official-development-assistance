require "rails_helper"
require "csv"

RSpec.describe ActivitySpendingBreakdown do
  let(:project) { travel_to_quarter(3, 2020) { create(:project_activity, :with_report) } }
  let(:report) { Report.for_activity(project).in_historical_order.first }
  let(:breakdown) { ActivitySpendingBreakdown.new(activity: project, report: report) }

  it "generates columns in the given order" do
    expect(breakdown.headers).to eq([
      "RODA identifier",
      "BEIS identifier",
      "Delivery partner identifier",
      "Title",
      "Description",
      "Programme status",
      "ODA eligibility",
    ])
  end

  it "exports some metadata relating to the activity" do
    presenter = ActivityPresenter.new(project)

    expect(breakdown.combined_hash).to include(
      "RODA identifier" => project.roda_identifier,
      "BEIS identifier" => project.beis_id,
      "Delivery partner identifier" => project.delivery_partner_identifier,
      "Title" => project.title,
      "Description" => project.description,
      "Programme status" => presenter.programme_status,
      "ODA eligibility" => presenter.oda_eligibility
    )
  end
end
