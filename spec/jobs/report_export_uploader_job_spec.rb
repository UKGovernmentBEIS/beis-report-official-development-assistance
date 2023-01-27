require "rails_helper"

RSpec.describe ReportExportUploaderJob, type: :job do
  let(:requester) { double(:user, email: "roger@example.com") }
  let(:report) { double(:report, save: true) }
  let(:row1) { double("row1") }
  let(:row2) { double("row1") }

  let(:report_export) do
    instance_double(
      Export::Report,
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
      allow(Report).to receive(:find).and_return(report)
      allow(Export::Report).to receive(:new).and_return(report_export)
      allow(Tempfile).to receive(:new).and_return(tempfile)
      allow(CSV).to receive(:open).and_yield(csv)
      allow(Export::S3Uploader).to receive(:new).and_return(uploader)
      allow(DownloadLinkMailer).to receive(:send_link).and_return(email)
      allow(report).to receive(:export_filename=)
    end

    it "asks the user object for the user with a given id" do
      ReportExportUploaderJob.perform_now(requester_id: "user123", report_id: double)

      expect(User).to have_received(:find).with("user123")
    end

    it "asks the report object for the report with a given id" do
      ReportExportUploaderJob.perform_now(requester_id: double, report_id: "report123")

      expect(Report).to have_received(:find).with("report123")
    end

    it "uses Export::Report to build the report CSV for the given report" do
      ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

      expect(Export::Report).to have_received(:new).with(report: report)
    end

    it "writes the report CSV to a 'tempfile'" do
      ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

      expect(CSV).to have_received(:open).with(tempfile, "wb", {headers: true})
      expect(csv).to have_received(:<<).with(%w[col1 col2])
      expect(csv).to have_received(:<<).with(row1)
      expect(csv).to have_received(:<<).with(row2)
    end

    it "uploads the file to S3" do
      ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

      expect(Export::S3Uploader).to have_received(:new)
        .with(
          file: tempfile,
          filename: "export_1234.csv",
          use_public_bucket: false
        )
      expect(uploader).to have_received(:upload)
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
        ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

        expect(Rails.logger).to have_received(:error).with(
          "Error uploading filename-xyz for roger@example.com"
        )
      end

      it "records the error at Rollbar for exception handling and debugging" do
        ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

        expect(Rollbar).to have_received(:log).with(
          :error,
          "Error uploading filename-xyz for roger@example.com",
          error
        )
      end

      it "does not re-raise the error as we don't wish to retry the job" do
        expect {
          ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)
        }.not_to raise_error
      end

      it "sends the email notifying the requester of failure uploading the report" do
        ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

        expect(DownloadLinkMailer)
          .to have_received(:send_failure_notification)
          .with(recipient: requester)
        expect(email).to have_received(:deliver)
      end
    end

    it "saves the uploaded filename in the report" do
      ReportExportUploaderJob.perform_now(requester_id: double, report_id: double)

      expect(report).to have_received(:export_filename=).with(upload.timestamped_filename)
      expect(report).to have_received(:save)
    end
  end
end
