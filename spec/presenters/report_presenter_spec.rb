# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportPresenter do
  describe "#state" do
    it "returns the string for the state" do
      report = build(:report, state: "inactive")
      result = described_class.new(report).state
      expect(result).to eql("Inactive")
    end
  end

  describe "#deadline" do
    it "returns the formatted date for the deadline" do
      report = build(:report, deadline: Date.today)
      result = described_class.new(report).deadline
      expect(result).to eql I18n.l(Date.today)
    end
  end

  describe "#financial_quarter_and_year" do
    it "returns the formatted financial quarter and year e.g. FQ1 2020-2021" do
      report = build(:report, financial_quarter: 1, financial_year: 2020)
      result = described_class.new(report).financial_quarter_and_year

      expect(result).to eql "FQ1 2020-2021"
    end

    it "returns nil when the report has no financial quarter or year" do
      report = build(:report, financial_quarter: nil, financial_year: nil)
      result = described_class.new(report).financial_quarter_and_year

      expect(result).to be_nil
    end
  end

  context "generating filenames" do
    let(:report) {
      build(:report,
        financial_quarter: 1,
        financial_year: 2020,
        fund: build(:fund_activity, :gcrf),
        organisation: build(:organisation, beis_organisation_reference: "BOR"),
        description: "My report")
    }

    describe "#filename_for_report_download" do
      it "returns the URL-encoded filename for the downloadable report" do
        result = described_class.new(report).filename_for_report_download

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-report.csv"
      end
    end

    describe "#filename_for_activities_template" do
      it "returns the URL-encoded filename for the activities template CSV dowload" do
        result = described_class.new(report).filename_for_activities_template

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-activities_upload.csv"
      end
    end

    describe "#filename_for_transactions_template" do
      it "returns the URL-encoded filename for the transactions template CSV dowload" do
        result = described_class.new(report).filename_for_transactions_template

        expect(result).to eql "FQ1 2020-2021-GCRF-BOR-transactions_upload.csv"
      end
    end

    describe "#filename_for_forecasts_template" do
      it "returns the URL-encoded filename for the transactions template CSV dowload" do
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
