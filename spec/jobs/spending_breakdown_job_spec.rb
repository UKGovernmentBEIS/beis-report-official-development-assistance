require "rails_helper"

RSpec.describe SpendingBreakdownJob, type: :job do
  let(:requester) { double(:user, email: "roger@example.com") }
  let(:fund_activity) { double(:fund_activity, save!: true) }
  let(:fund) { double(:fund, activity: fund_activity) }
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
  let(:upload) do
    OpenStruct.new(
      url: "https://example.com/presigned_url",
      timestamped_filename: "timestamped_filename.csv"
    )
  end
  let(:uploader) { instance_double(Export::S3Uploader, upload: upload) }
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
      allow(fund_activity).to receive(:spending_breakdown_filename=)
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

    it "uploads the file to the public S3 bucket" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(Export::S3Uploader).to have_received(:new)
        .with(
          file: tempfile,
          filename: "export_1234.csv",
          use_public_bucket: true
        )
      expect(uploader).to have_received(:upload)
    end

    it "saves the uploaded filename in the fund activity" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(fund_activity).to have_received(:spending_breakdown_filename=).with(upload.timestamped_filename)
      expect(fund_activity).to have_received(:save!)
    end

    context "when the uploader raises an error" do
      let(:error) { Export::S3UploadError.new("Error uploading filename-xyz") }

      before do
        allow(uploader).to receive(:upload).and_raise(error)
        allow(Rails.logger).to receive(:error)
        allow(Rollbar).to receive(:log)
        allow(DownloadLinkMailer).to receive(:send_failure_notification).and_return(email)
      end

      it "logs the error, including the identity of the requester" do
        SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

        expect(Rails.logger).to have_received(:error).with(
          "Error uploading filename-xyz for roger@example.com"
        )
      end

      it "records the error at Rollbar for exception handling and debugging" do
        SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

        expect(Rollbar).to have_received(:log).with(
          :error,
          "Error uploading filename-xyz for roger@example.com",
          error
        )
      end

      it "does not re-raise the error as we don't wish to retry the job" do
        expect {
          SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)
        }.not_to raise_error
      end

      it "does not try to send the email with the download link" do
        SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

        expect(DownloadLinkMailer).not_to have_received(:send_link)
      end

      it "sends the email notifying the requester of failure creating the report" do
        SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

        expect(DownloadLinkMailer)
          .to have_received(:send_failure_notification)
          .with(recipient: requester)
        expect(email).to have_received(:deliver)
      end
    end

    it "emails the requesting user to let them know the download is ready" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: double)

      expect(DownloadLinkMailer).to have_received(:send_link).with(
        recipient: requester,
        file_name: "timestamped_filename.csv"
      )
      expect(email).to have_received(:deliver)
    end
  end
end
