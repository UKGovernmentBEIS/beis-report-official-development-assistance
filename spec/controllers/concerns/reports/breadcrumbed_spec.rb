require "rails_helper"

class StubController < Staff::BaseController
  include Reports::Breadcrumbed

  def show
    activity = Activity.find(params[:id])
    prepare_default_activity_trail(activity)
  end
end

RSpec.describe StubController, type: :controller do
  let(:user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  before do
    allow(subject).to receive(:reports_path).and_return("reports_path")
    allow(subject).to receive(:report_path).and_return("report_path")
  end

  context "when the report is historic" do
    let(:report) { build(:report, state: :approved) }

    it "adds the historic reports path to the breadcrumbs" do
      expect(subject).to receive(:add_breadcrumb).with("Historic Reports", reports_path(anchor: "historic"))
      expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))

      subject.prepare_default_report_trail(report)
    end
  end

  context "when the report is current" do
    let(:report) { build(:report, state: :active) }

    it "adds the current reports path to the breadcrumbs" do
      expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
      expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))

      subject.prepare_default_report_trail(report)
    end
  end
end
