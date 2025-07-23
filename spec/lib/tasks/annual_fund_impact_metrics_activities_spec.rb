require "tempfile"

RSpec.describe "rake activities:annual_fund_impact_metrics", type: :task do
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

  it "excludes Activities with `delivery`, `agreement_in_place`, `open_for_applications`, `stopped`, or `planned` statuses" do
    completed_activity = create(:programme_activity, programme_status: "completed")
    delivery_activity = create(:programme_activity, programme_status: "delivery")
    agreement_in_place_activity = create(:programme_activity, programme_status: "agreement_in_place")
    open_for_applications_activity = create(:programme_activity, programme_status: "open_for_applications")
    stopped_activity = create(:programme_activity, programme_status: "stopped")
    planned_activity = create(:programme_activity, programme_status: "planned")

    excluded_activities = [
      delivery_activity,
      agreement_in_place_activity,
      open_for_applications_activity,
      stopped_activity,
      planned_activity
    ]

    (excluded_activities + [completed_activity]).each do |activity|
      create(:actual, parent_activity: activity)
    end

    task.invoke(test_csv.path)
    result = test_csv.readlines

    expect(result.second).to include(completed_activity.roda_identifier)

    excluded_activities_present = result.any? do |activity|
      excluded_activities.map(&:roda_identifier).any? { |id| activity.include?(id) }
    end
    expect(excluded_activities_present).to be(false)
  end

  it "includes Activities with `completed` statuses if there are no Actuals reported in the last 2 years" do
    completed_activity = create(:programme_activity, programme_status: "completed")
    create(:actual, date: Date.today, parent_activity: completed_activity, report: nil)

    completed_over_2_years_ago_activity = create(:programme_activity, programme_status: "completed")
    create(:actual, date: 2.years.ago - 1.day, parent_activity: completed_over_2_years_ago_activity, report: nil)

    task.invoke(test_csv.path)
    result = test_csv.readlines

    expect(result.second).to include(completed_activity.roda_identifier)

    excluded_activities_present = result.any? do |activity|
      activity.include?(completed_over_2_years_ago_activity.roda_identifier)
    end

    expect(excluded_activities_present).to be(false)
  end

  it "excludes Activities with `completed` statuses if it has no Actuals" do
    completed_activity = create(:programme_activity, programme_status: "completed")
    create(:actual, date: Date.today, parent_activity: completed_activity, report: nil)

    completed_activity_with_no_actual = create(:programme_activity, programme_status: "completed")

    task.invoke(test_csv.path)
    result = test_csv.readlines

    expect(result.second).to include(completed_activity.roda_identifier)

    excluded_activities_present = result.any? do |activity|
      activity.include?(completed_activity_with_no_actual.roda_identifier)
    end

    expect(excluded_activities_present).to be(false)
  end

  it "generates a CSV file of Activities ordered by organisation name and status" do
    completed_activity = create(:programme_activity, programme_status: "completed")
    create(:actual, date: Date.today, parent_activity: completed_activity, report: nil)
    beis_organisation = completed_activity.organisation
    aardvark_organisation = create(:beis_organisation, name: "Department for Aardvarks", iati_reference: "CZH-COH-111")
    decided_activity = create(:programme_activity, organisation: aardvark_organisation, programme_status: "decided")
    review_activity = create(:programme_activity, organisation: aardvark_organisation, programme_status: "review")

    task.invoke(test_csv.path)
    result = test_csv.readlines

    expect(result.count).to be 4
    expect(result[0]).to eq "Partner Organisation name,Activity name,RODA ID,Partner Organisation ID,Status,Level\n"
    expect(result[1]).to eq "#{aardvark_organisation.name},#{review_activity.title},#{review_activity.roda_identifier},#{review_activity.partner_organisation_identifier},Review,Programme (level B)\n"
    expect(result[2]).to eq "#{aardvark_organisation.name},#{decided_activity.title},#{decided_activity.roda_identifier},#{decided_activity.partner_organisation_identifier},Decided,Programme (level B)\n"
    expect(result[3]).to eq "\"#{beis_organisation.name}\",#{completed_activity.title},#{completed_activity.roda_identifier},#{completed_activity.partner_organisation_identifier},Completed,Programme (level B)\n"
  end
end
