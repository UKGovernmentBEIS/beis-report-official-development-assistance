require "rails_helper"

RSpec.describe ReportHelper, type: :helper do
  describe "#report_download_link" do
    context "when the report doesn't have an export_url" do
      let(:report) { create(:report) }

      it "returns the report show path in CSV format" do
        expect(helper.report_download_link(report)).to eq(report_path(report, format: :csv))
      end
    end

    context "when the report has an export_url" do
      let(:report) { create(:report, export_url: "s3_link") }

      it "returns the export_url" do
        expect(helper.report_download_link(report)).to eq("s3_link")
      end
    end
  end
end
