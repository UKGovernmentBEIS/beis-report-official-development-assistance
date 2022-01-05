require "rails_helper"

RSpec.describe Export::S3Uploader do
  let(:response) { double("response", etag: double) }
  let(:file) { Tempfile.open("tempfile") { |f| f << "my export here" } }
  let(:aws_client) { instance_double(Aws::S3::Client, put_object: response) }
  let(:timestamp) { Time.current }
  let(:filename) { "export-file-#{timestamp.to_formatted_s(:number)}.csv" }

  let(:s3_object) { double("s3 object", public_url: "https://s3.example.com/xyz321")}
  let(:s3_bucket) { double("s3 bucket", object: s3_object) }
  let(:s3_bucket_finder) { instance_double(Aws::S3::Resource, bucket: s3_bucket) }

  subject do
    travel_to(timestamp) do
      Export::S3Uploader.new(file)
    end
  end

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3_bucket_finder)
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

    it "sets the filename using a timestamp" do
      subject.upload

      expect(aws_client).to have_received(:put_object).with(hash_including(key: filename))
    end

    context "when the response from S3 has an _etag_" do
      let(:response) { double("response", etag: "abc123") }

      it "uses Aws::S3:Resource to retrieve the uploaded object from its bucket" do
        subject.upload

        expect(Aws::S3::Resource).to have_received(:new).with(client: aws_client)
        expect(s3_bucket_finder).to have_received(:bucket).with(Export::S3UploaderConfig.bucket)
        expect(s3_bucket).to have_received(:object).with(filename)
      end

      it "returns the public_url of the uploaded object" do
        expect(subject.upload).to eq("https://s3.example.com/xyz321")
      end
    end

    context "when the response from S3 does not have an _etag_" do
      let(:response) { double("response", etag: nil) }

      it "raises an error, including the filename for information" do
        message = "Unexpected response. Error uploading report #{filename}"
        expect { subject.upload }.to raise_error(Export::S3UploadError, message)
      end
    end

    context "when the attempt to upload the file raises an error" do
      before do
        allow(aws_client).to receive(:put_object).and_raise("There has been a problem!")
      end

      it "re-raises the error, adding the filename for information" do
        enriched_message = "There has been a problem! Error uploading report #{filename}"
        expect { subject.upload }.to raise_error(Export::S3UploadError, enriched_message)
      end
    end
  end
end
