require "rails_helper"

class StubController < Staff::BaseController
  include Activities::Breadcrumbed

  def show
    activity = Activity.find(params[:id])
    prepare_default_activity_trail(activity)
  end
end

RSpec.describe StubController, type: :controller do
  let(:user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  before do
    allow(subject).to receive(:historic_organisation_activities_path).and_return("historic_index_path")
    allow(subject).to receive(:organisation_activities_path).and_return("current_index_path")
    allow(subject).to receive(:organisation_activity_path).and_return("activity_path")
  end

  context "for a delivery partner user" do
    before do
      allow(subject).to receive(:current_user).and_return(user)
    end

    context "for a historic project activity" do
      let(:activity) { build(:project_activity, programme_status: "completed") }

      it "adds the historic index path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.historic_index"), "historic_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a current project activity" do
      let(:activity) { build(:project_activity) }

      it "adds the current index path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.current_index"), "current_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a third-party project" do
      let(:activity) { build(:third_party_project_activity) }

      it "adds the parent project and programme activities to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.current_index"), "current_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a programme" do
      let(:activity) { build(:programme_activity) }

      it "adds the current index path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.current_index"), "current_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a fund" do
      let(:activity) { build(:fund_activity) }

      it "does not add anything to the breadcrumb stack" do
        expect(subject).to_not receive(:add_breadcrumb)

        subject.prepare_default_activity_trail(activity)
      end
    end

    context "when the activity is untitled" do
      it "sets an 'Untitled' title" do
        activity = build(:project_activity, title: nil)

        expect(subject).to receive(:add_breadcrumb).twice
        expect(subject).to receive(:add_breadcrumb).with("Untitled activity", "activity_path")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end
    end
  end

  context "for a BEIS user" do
    before do
      allow(subject).to receive(:current_user).and_return(beis_user)
    end

    context "for a historic project activity" do
      let(:activity) { build(:project_activity, programme_status: "completed") }

      it "adds the historic index path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.organisation_historic_index", org_name: activity.organisation.name), "historic_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a current project activity" do
      let(:activity) { build(:project_activity) }

      it "adds the current index path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.organisation_current_index", org_name: activity.organisation.name), "current_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a third-party project" do
      let(:activity) { build(:third_party_project_activity) }

      it "adds the parent project and programme activities to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(t("page_content.breadcrumbs.organisation_current_index", org_name: activity.organisation.name), "current_index_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end

      context "when the user has accessed the activity from a report" do
        let(:report) { create(:report) }

        before do
          BreadcrumbContext.new(session).set(type: :report, model: report)
        end

        it "adds the report's path to the breadcrumb stack" do
          expect(subject).to receive(:add_breadcrumb).with("Current Reports", reports_path)
          expect(subject).to receive(:add_breadcrumb).with(t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year), report_path(report))
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
          expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

          subject.prepare_default_activity_trail(activity)
        end
      end
    end

    context "for a programme" do
      let(:activity) { build(:programme_activity) }

      it "adds the fund and programme paths to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(activity.parent.title, "activity_path")
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end
    end

    context "for a fund" do
      let(:activity) { build(:fund_activity) }

      it "adds the fund path to the breadcrumb stack" do
        expect(subject).to receive(:add_breadcrumb).with(activity.title, "activity_path")

        subject.prepare_default_activity_trail(activity)
      end

      it "allows the tab to be specified for the leaf activity" do
        expect(subject).to receive(:organisation_activity_path).with(activity.organisation, activity, tab: "tab")

        subject.prepare_default_activity_trail(activity, tab: "tab")
      end
    end
  end
end
