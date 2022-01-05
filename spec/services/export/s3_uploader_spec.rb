require "rails_helper"

RSpec.describe Export::S3Uploader do
  let(:response) { double("response", etag: double) }
  let(:file) { Tempfile.open("tempfile") { |f| f << "my export here" } }
  let(:aws_client) { instance_double(Aws::S3::Client, put_object: response) }

  subject { Export::S3Uploader.new(file) }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
  end

  describe "#upload" do
    it "uploads the given file" do
      subject.upload

      expect(aws_client).to have_received(:put_object).with(hash_including(body: file))
    end

    it "uploads to the bucket defined by the S3UploaderConfig" do
      subject.upload

      expect(aws_client).to have_received(:put_object).with(
        hash_including(bucket: Export::S3UploaderConfig.bucket)
      )
    end

    it "sets the filename using a timestamp"

    context "when the response from S3 has an _etag_" do
      it "returns the public_url of the uploaded object"
    end

    context "when the response from S3 does not have an _etag_" do
      it "logs the error"
      it "logs the error at Rollbar"
      it "returns _false_"
    end

    context "when the attempt to upload the file raises an error" do
      it "logs the error"
      it "logs the error at Rollbar"
      it "returns _false_"
    end
  end
end
