require "rails_helper"

RSpec.describe SpendingBreakdownJob, type: :job do
  let(:requester) { double(:user) }
  let(:fund) { double(:fund) }
  let(:row1) { double("row1") }
  let(:row2) { double("row1") }

  let(:breakdown) do
    instance_double(
      Export::SpendingBreakdown,
      filename: "export_1234.csv",
      headers: %w[col1 col2],
      rows: [row1, row2]
    )
  end
  let(:tempfile) { double("tempfile") }
  let(:csv) { double("csv", "<<" => true) }
  let(:uploader) { instance_double(Export::S3Uploader, upload: "https://example.com/abc.csv") }
  let(:email) { double("email", deliver: double) }

  describe "#perform" do
    before do
      allow(User).to receive(:find).and_return(requester)
      allow(Fund).to receive(:new).and_return(fund)
      allow(Export::SpendingBreakdown).to receive(:new).and_return(breakdown)
      allow(Tempfile).to receive(:new).and_return(tempfile)
      allow(CSV).to receive(:open).and_yield(csv)
      allow(Export::S3Uploader).to receive(:new).and_return(uploader)
      allow(DownloadLinkMailer).to receive(:send_link).and_return(email)
    end

    it "asks the user object for the user with a given id" do
      SpendingBreakdownJob.perform_now(requester_id: "user123", fund_id: double)

      expect(User).to have_received(:find).with("user123")
    end

    it "asks the fund object for the fund with a given id" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: "fund123")

      expect(Fund).to have_received(:new).with("fund123")
    end

    it "uses Export::SpendingBreakdown to build the breakdown for the given fund" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(Export::SpendingBreakdown).to have_received(:new).with(source_fund: fund)
    end

    it "writes the breakdown to a 'tempfile'" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(CSV).to have_received(:open).with(tempfile, "wb", {headers: true})
      expect(csv).to have_received(:<<).with(%w[col1 col2])
      expect(csv).to have_received(:<<).with(row1)
      expect(csv).to have_received(:<<).with(row2)
    end

    it "uploads the file to S3" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(Export::S3Uploader).to have_received(:new).with(tempfile)
      expect(uploader).to have_received(:upload)
    end

    it "emails a download link to the requesting user" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(DownloadLinkMailer).to have_received(:send_link).with(
        recipient: requester,
        file_url: "https://example.com/abc.csv",
        file_name: "export_1234.csv"
      )
      expect(email).to have_received(:deliver)
    end
  end
end
