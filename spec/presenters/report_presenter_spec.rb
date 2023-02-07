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

  describe "#approved_at" do
    it "returns the formatted datetime for the Report's approval date" do
      now = Time.now
      report = build(:report, approved_at: now)
      result = described_class.new(report).approved_at
      expect(result).to eql I18n.l(now, format: :detailed)
    end
  end

  describe "#uploaded_at" do
    context "when the report has an `export_filename`" do
      it "parses the timestamp from the uploaded report's filename" do
        report = build(:report, export_filename: "FQ4 2020-2021_GCRF_BA_report-20230111184653.csv")
        result = described_class.new(report).uploaded_at
        expect(result).to eql "2023-01-11 18:46"
      end
    end

    context "when the report has no `export_filename`" do
      it "returns nil" do
        report = build(:report, export_filename: nil)
        result = described_class.new(report).uploaded_at
        expect(result).to be_nil
      end
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

      context "ISPF non-ODA" do
        it "returns the URL-encoded filename for the activities template CSV dowload" do
          report.update(fund: create(:fund_activity, :ispf))

          result = described_class.new(report).filename_for_activities_template(is_oda: false)

          expect(result).to eql "FQ1 2020-2021-ISPF-non-ODA-BOR-activities_upload.csv"
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
