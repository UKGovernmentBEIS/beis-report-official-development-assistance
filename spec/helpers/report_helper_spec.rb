require "rails_helper"

RSpec.describe ReportHelper, type: :helper do
  describe "#report_download_link" do
    context "when the report doesn't have an export_filename" do
      let(:report) { create(:report) }

      it "returns the report show path in CSV format" do
        expect(helper.report_download_link(report)).to eq(report_path(report, format: :csv))
      end
    end

    context "when the report has an export_filename" do
      let(:report) { create(:report, export_filename: "exported_csv") }

      it "returns the report download path" do
        expect(helper.report_download_link(report)).to eq(download_report_path(report))
      end
    end
  end
end
