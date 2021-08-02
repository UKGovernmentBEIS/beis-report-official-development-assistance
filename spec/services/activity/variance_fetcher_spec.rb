require "rails_helper"

RSpec.describe Activity::VarianceFetcher do
  let(:report) { build(:report) }
  let(:projects_finder) { double("ProjectsForReportFinder", call: activities) }
  let(:fetcher) { described_class.new(report) }

  before do
    allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(projects_finder)
  end

  describe "#activities" do
    subject { fetcher.activities }

    let(:activity_with_variance) { build(:project_activity) }
    let(:activity_without_variance) { build(:project_activity) }

    let(:activities) { [activity_with_variance, activity_without_variance] }

    before do
      allow(activity_with_variance).to receive(:variance_for_report_financial_quarter).and_return(100)
      allow(activity_without_variance).to receive(:variance_for_report_financial_quarter).and_return(0)
    end

    it "calls variance_for_report_financial_quarter with the correct report" do
      subject
      expect(activity_with_variance).to have_received(:variance_for_report_financial_quarter).with(report: report)
      expect(activity_without_variance).to have_received(:variance_for_report_financial_quarter).with(report: report)
    end

    it "only returns activities that have a variance" do
      expect(subject).to eq([activity_with_variance])
    end
  end

  describe "#total" do
    subject { fetcher.total }

    let(:activity_1) { build(:project_activity) }
    let(:activity_2) { build(:project_activity) }
    let(:activity_3) { build(:project_activity) }

    let(:activities) { [activity_1, activity_2, activity_3] }

    before do
      allow(activity_1).to receive(:variance_for_report_financial_quarter).and_return(100)
      allow(activity_2).to receive(:variance_for_report_financial_quarter).and_return(200)
      allow(activity_3).to receive(:variance_for_report_financial_quarter).and_return(0)
    end

    it "sums all the variances" do
      expect(subject).to eq(300)
    end
  end
end
