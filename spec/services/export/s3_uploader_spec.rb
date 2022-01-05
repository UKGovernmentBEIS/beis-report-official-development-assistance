require "rails_helper"

RSpec.describe Export::S3Uploader do
  describe "#upload" do
    it "uploads the given file"
    it "uploads to the bucket defined in by the S3UploaderConfig"
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
