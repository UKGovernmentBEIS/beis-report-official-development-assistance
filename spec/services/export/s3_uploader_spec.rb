require "rails_helper"

RSpec.describe Export::S3Uploader do
  let(:response) { double("response", etag: double) }
  let(:file) { Tempfile.open("tempfile") { |f| f << "my export here" } }
  let(:aws_credentials) { double("aws credentials") }
  let(:ecs_credentials) { double("ecs credentials") }
  let(:aws_client) { instance_double(Aws::S3::Client, put_object: response) }
  let(:timestamp) { Time.current }
  let(:timestamped_filename) { "spending_breakdown-#{timestamp.to_formatted_s(:number)}.csv" }

  let(:s3_object) { double("s3 object", public_url: "https://s3.example.com/xyz321") }
  let(:s3_bucket) { double("s3 bucket", object: s3_object) }
  let(:s3_bucket_finder) { instance_double(Aws::S3::Resource, bucket: s3_bucket) }
  let(:s3_config) {
    instance_double(
      Export::S3Config,
      key_id: "key id",
      secret_key: "secret key",
      region: "region",
      bucket: s3_bucket
    )
  }

  let(:bucket_name) { "dsit_exports_bucket" }

  subject do
    travel_to(timestamp) do
      Export::S3Uploader.new(file: file, filename: "spending_breakdown.csv")
    end
  end

  before do
    allow(Aws::Credentials).to receive(:new).and_return(aws_credentials)
    allow(Aws::ECSCredentials).to receive(:new).and_return(ecs_credentials)
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3_bucket_finder)
    allow(Export::S3Config).to receive(:new).and_return(s3_config)
  end

  describe "#initialize" do
    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: bucket_name) { example.run }
      end

      context "when instantiating the Aws::S3::Client" do
        it "sets credentials: using an Aws::ECSCredentials object" do
          subject

          expect(Aws::ECSCredentials).to have_received(:new).with({retries: 3})
          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            credentials: ecs_credentials
          ))
        end

        it "sets region: using the hardcoded eu-west-2 region" do
          subject

          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            region: "eu-west-2"
          ))
        end
      end
    end

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is not present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: nil) { example.run }
      end

      context "when instantiating the Aws::S3::Client" do
        it "sets credentials: using an Aws::Credentials object" do
          subject

          expect(Aws::Credentials).to have_received(:new).with(
            s3_config.key_id,
            s3_config.secret_key
          )
          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            credentials: aws_credentials
          ))
        end

        it "sets region: using the region from the S3Config" do
          subject

          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            region: s3_config.region
          ))
        end
      end
    end
  end

  describe "#upload" do
    it "uploads the given file" do
      subject.upload

      expect(aws_client).to have_received(:put_object).with(hash_including(body: file))
    end

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: bucket_name) { example.run }
      end

      it "uploads to the bucket defined by the env var" do
        subject.upload

        expect(aws_client).to have_received(:put_object).with(
          hash_including(bucket: bucket_name)
        )
      end

      it "does not use the S3Config" do
        subject.upload

        expect(s3_config).to_not have_received(:region)
        expect(s3_config).to_not have_received(:bucket)
        expect(s3_config).to_not have_received(:key_id)
        expect(s3_config).to_not have_received(:secret_key)
      end
    end

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is not present" do
      it "uploads to the bucket defined by the S3Config" do
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: nil) do
          subject.upload

          expect(aws_client).to have_received(:put_object).with(
            hash_including(bucket: s3_config.bucket)
          )
        end
      end
    end

    it "sets the filename using a timestamp" do
      subject.upload

      expect(aws_client).to have_received(:put_object).with(hash_including(key: timestamped_filename))
    end

    context "when the response from S3 has an _etag_" do
      let(:response) { double("response", etag: "abc123") }
      let(:s3_object) { double("s3 object").as_null_object }

      it "does not ask for a public_url" do
        subject.upload

        expect(s3_object).not_to have_received(:public_url)
      end

      it "returns the timestamped filename of the uploaded object" do
        expect(subject.upload).to eq(
          OpenStruct.new(
            timestamped_filename: timestamped_filename
          )
        )
      end
    end

    context "when the response from S3 does not have an _etag_" do
      let(:response) { double("response", etag: nil) }

      it "raises an error, including the filename for information" do
        message = "Unexpected response. Error uploading report #{timestamped_filename}"
        expect { subject.upload }.to raise_error(Export::S3UploadError, message)
      end
    end

    context "when the attempt to upload the file raises an error" do
      before do
        allow(aws_client).to receive(:put_object).and_raise("There has been a problem!")
      end

      it "re-raises the error, adding the filename for information" do
        enriched_message = "There has been a problem! #{I18n.t("upload.failure", filename: timestamped_filename)}"
        expect { subject.upload }.to raise_error(Export::S3UploadError, enriched_message)
      end
    end
  end
end
