# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportPresenter do
  describe "#state" do
    it "returns the string for the state" do
      report = build(:report, state: "active")
      result = described_class.new(report).state
      expect(result).to eql("Active")
    end
  end

  describe "#can_edit_message" do
    it "returns the right message corresponding to the report state" do
      report = build(:report, state: "active")
      result = described_class.new(report).can_edit_message
      expect(result).to eql(t("label.report.can_edit.active"))

      report.state = "awaiting_changes"
      result = described_class.new(report).can_edit_message
      expect(result).to eql(t("label.report.can_edit.awaiting_changes"))

      report.state = "in_review"
      result = described_class.new(report).can_edit_message
      expect(result).to eql(t("label.report.can_edit.in_review"))

      report.state = "submitted"
      result = described_class.new(report).can_edit_message
      expect(result).to eql(t("label.report.can_edit.submitted"))
    end
  end

  describe "#deadline" do
    it "returns the formatted date for the deadline" do
      report = build(:report, deadline: Date.today)
      result = described_class.new(report).deadline
      expect(result).to eql I18n.l(Date.today)
    end
  end

  context "generating filenames" do
    let(:report) {
      build(:report,
        financial_quarter: 1,
        financial_year: 2020,
        fund: create(:fund_activity, :gcrf),
        organisation: build(:partner_organisation, beis_organisation_reference: "BOR"),
        description: "My report")
    }

    describe "#filename_for_report_download" do
      it "returns the URL-encoded filename for the downloadable report" do
        result = described_class.new(report).filename_for_report_download

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-report.csv"
      end
    end

    describe "#filename_for_activities_template" do
      context "non-ISPF" do
        it "returns the URL-encoded filename for the activities template CSV dowload" do
          result = described_class.new(report).filename_for_activities_template(is_oda: nil)

          expect(result).to eql "FQ1 2020-2021-GCRF-BOR-activities_upload.csv"
        end
      end

      context "ISPF ODA" do
        it "returns the URL-encoded filename for the activities template CSV dowload" do
          report.update(fund: create(:fund_activity, :ispf))

          result = described_class.new(report).filename_for_activities_template(is_oda: true)

          expect(result).to eql "FQ1 2020-2021-ISPF-ODA-BOR-activities_upload.csv"
        end
      end
    end

    describe "#filename_for_actuals_template" do
      it "returns the URL-encoded filename for the actuals template CSV dowload" do
        result = described_class.new(report).filename_for_actuals_template

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-actuals_upload.csv"
      end
    end

    describe "#filename_for_forecasts_template" do
      it "returns the URL-encoded filename for the forecasts template CSV dowload" do
        result = described_class.new(report).filename_for_forecasts_template

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-forecasts_upload.csv"
      end
    end

    describe "#filename_for_all_reports_download" do
      it "returns the URL-encoded filename for the aggregated download of all reports" do
        result = described_class.new(report).filename_for_all_reports_download

        expect(result).to eql "FQ1 2020-2021-All-Reports.csv"
      end
    end
  end
end
