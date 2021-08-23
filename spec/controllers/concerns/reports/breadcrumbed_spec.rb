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
    allow(subject).to receive(:report_variance_path).and_return("report_path")
  end

  context "when the report is approved" do
    let(:report) { build(:report, state: :approved) }

    describe "#prepare_default_report_trail" do
      it "adds the approved reports path to the breadcrumbs" do
        expect(subject).to receive(:add_breadcrumb).with("Approved Reports", reports_path(anchor: "approved"))
        expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))

        subject.prepare_default_report_trail(report)
      end

      it "sets the breadcrumb context in the session" do
        subject.prepare_default_report_trail(report)

        expect(session[:breadcrumb_context]).to eq({
          type: :report,
          model: report,
        })
      end
    end

    describe "#prepare_default_report_variance_trail" do
      it "adds the approved reports path and the variance to the breadcrumbs" do
        expect(subject).to receive(:add_breadcrumb).with("Approved Reports", reports_path(anchor: "approved"))
        expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_variance_path(report))

        subject.prepare_default_report_trail(report)
      end
    end
  end

  context "when the report is current" do
    let(:report) { build(:report, state: :active) }

    describe "#prepare_default_report_trail" do
      it "adds the current reports path to the breadcrumbs" do
        expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
        expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))

        subject.prepare_default_report_trail(report)
      end

      it "sets the breadcrumb context in the session" do
        subject.prepare_default_report_trail(report)

        expect(session[:breadcrumb_context]).to eq({
          type: :report,
          model: report,
        })
      end
    end

    describe "#prepare_default_report_variance_trail" do
      it "adds the approved reports path and the variance to the breadcrumbs" do
        expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
        expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_variance_path(report))

        subject.prepare_default_report_trail(report)
      end
    end
  end
end
