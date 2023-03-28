require "tempfile"

RSpec.describe "rake activities:annual_fund_impact_metrics", type: :task do
  let!(:completed_activity) { create(:fund_activity, programme_status: "completed") }
  let!(:actual_2_years_ago) { create(:actual, date: 2.years.ago, parent_activity: completed_activity, report: nil) }
  let!(:beis_organisation) { completed_activity.organisation }
  let!(:completed_activity_no_actuals) { create(:fund_activity, programme_status: "completed") }
  let!(:decided_activity) { create(:fund_activity, organisation: aardvark_organisation, programme_status: "decided") }
  let!(:review_activity) { create(:fund_activity, organisation: aardvark_organisation, programme_status: "review") }
  let!(:aardvark_organisation) { create(:beis_organisation, name: "Department for Aardvarks", iati_reference: "CZH-COH-111") }

  let!(:delivery_activity) { create(:fund_activity, programme_status: "delivery") }
  let!(:agreement_in_place_activity) { create(:fund_activity, programme_status: "agreement_in_place") }
  let!(:open_for_applications_activity) { create(:fund_activity, programme_status: "open_for_applications") }
  let!(:stopped_activity) { create(:fund_activity, programme_status: "stopped") }

  let!(:completed_over_2_years_ago_activity) { create(:fund_activity, programme_status: "completed") }
  let!(:actual_over_2_years_ago) { create(:actual, date: 2.years.ago - 1.day, parent_activity: completed_over_2_years_ago_activity, report: nil) }

  let(:test_csv) { Tempfile.new(["fake", ".csv"]) }

  before { freeze_time }

  after do
    subject.reenable
    test_csv.unlink
  end

  subject { Rake::Task["activities:annual_fund_impact_metrics"] }

  context "when the CSV path is not provided" do
    before { allow(CSV).to receive(:open).and_return(nil) }

    it "uses the default path" do
      task.invoke

      expect(CSV).to have_received(:open).with("tmp/annual_fund_impact_metrics.csv", "wb")
    end
  end

  it "excludes Activities with `delivery`, `agreement_in_place`, `open_for_applications`, or `stopped` statuses" do
    excluded_activity_titles = [
      delivery_activity.title,
      agreement_in_place_activity.title,
      open_for_applications_activity.title,
      stopped_activity.title
    ]

    task.invoke(test_csv.path)
    result = test_csv.readlines

    excluded_activities_present = result.any? do |activity|
      excluded_activity_titles.any? { |title| activity.include?(title) }
    end

    expect(excluded_activities_present).to be(false)
  end

  it "excludes Activities with `completed` statuses if there are no Actuals reported in the last 2 years" do
    excluded_activity_titles = [completed_over_2_years_ago_activity.title]

    task.invoke(test_csv.path)
    result = test_csv.readlines

    excluded_activities_present = result.any? do |activity|
      excluded_activity_titles.any? { |title| activity.include?(title) }
    end

    expect(excluded_activities_present).to be(false)
  end

  it "excludes Activities with `completed` statuses if it has no Actuals" do
    excluded_activity_titles = [completed_activity_no_actuals.title]

    task.invoke(test_csv.path)
    result = test_csv.readlines

    excluded_activities_present = result.any? do |activity|
      excluded_activity_titles.any? { |title| activity.include?(title) }
    end

    expect(excluded_activities_present).to be(false)
  end

  it "generates a CSV file of Activities ordered by organisation name and status" do
    task.invoke(test_csv.path)
    result = test_csv.readlines

    expect(result.count).to be 4
    expect(result[0]).to eq "Partner Organisation name,Activity name,RODA ID,Partner Organisation ID,Status\n"
    expect(result[1]).to eq "#{aardvark_organisation.name},#{review_activity.title},#{review_activity.roda_identifier},#{review_activity.partner_organisation_identifier},#{review_activity.programme_status}\n"
    expect(result[2]).to eq "#{aardvark_organisation.name},#{decided_activity.title},#{decided_activity.roda_identifier},#{decided_activity.partner_organisation_identifier},#{decided_activity.programme_status}\n"
    expect(result[3]).to eq "\"#{beis_organisation.name}\",#{completed_activity.title},#{completed_activity.roda_identifier},#{completed_activity.partner_organisation_identifier},#{completed_activity.programme_status}\n"
  end
end
