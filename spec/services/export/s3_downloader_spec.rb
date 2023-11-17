require "rails_helper"

RSpec.describe Export::S3Downloader do
  let(:response_body) { double("response_body", read: double) }
  let(:response) { double("response", body: response_body) }
  let(:aws_credentials) { double("aws credentials") }
  let(:ecs_credentials) { double("ecs credentials") }
  let(:aws_client) { instance_double(Aws::S3::Client, get_object: response) }

  let(:s3_bucket) { double("s3 bucket") }
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
  let(:filename) { "Q1_report0101202312345.csv" }

  subject {
    Export::S3Downloader.new(filename: filename)
  }

  before do
    allow(Aws::Credentials).to receive(:new).and_return(aws_credentials)
    allow(Aws::ECSCredentials).to receive(:new).and_return(ecs_credentials)
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
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
        it "sets `credentials:` using an Aws::Credentials object" do
          subject

          expect(Aws::Credentials).to have_received(:new).with(
            s3_config.key_id,
            s3_config.secret_key
          )
          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            credentials: aws_credentials
          ))
        end

        it "sets `region:` using the region from the S3Config" do
          subject

          expect(Aws::S3::Client).to have_received(:new).with(hash_including(
            region: s3_config.region
          ))
        end
      end
    end
  end

  describe "#download" do
    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: bucket_name) { example.run }
      end

      it "gets the specified report CSV from the bucket defined by the env var" do
        subject.download

        expect(aws_client).to have_received(:get_object).with(
          bucket: bucket_name,
          key: filename,
          response_content_type: "text/csv"
        )
        expect(response).to have_received(:body)
        expect(response_body).to have_received(:read)
      end

      it "does not use the S3Config" do
        subject.download

        expect(s3_config).to_not have_received(:region)
        expect(s3_config).to_not have_received(:bucket)
        expect(s3_config).to_not have_received(:key_id)
        expect(s3_config).to_not have_received(:secret_key)
      end
    end

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is not present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: nil) { example.run }
      end

      it "gets the specified report CSV from the bucket in the config" do
        subject.download

        expect(aws_client).to have_received(:get_object).with(
          bucket: s3_bucket,
          key: filename,
          response_content_type: "text/csv"
        )
        expect(response).to have_received(:body)
        expect(response_body).to have_received(:read)
      end
    end

    context "when something goes wrong with fetching the object from S3" do
      before do
        allow(aws_client).to receive(:get_object).and_raise("There has been a problem!")
      end

      it "re-raises the error, adding the filename for information" do
        enriched_message = "There has been a problem! #{I18n.t("download.failure", filename: filename)}"
        expect { subject.download }.to raise_error(Export::S3DownloaderError, enriched_message)
      end
    end
  end
end
