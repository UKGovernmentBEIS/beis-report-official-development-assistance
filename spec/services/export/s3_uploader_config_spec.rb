require "rails_helper"

module Export
  RSpec.describe S3UploaderConfig do
    subject(:config) { S3UploaderConfig.new(use_public_bucket: true) }

    context "when an expected credential is missing from VCAP_SERVICES" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
                   "name": "beis-roda-staging-s3-export-download-bucket",
                   "credentials":{
                      "bucket_name":"exports_bucket",
                      "aws_access_key_id":"KEY_ID",
                      "aws_secret_access_key":"SECRET_KEY"
                   }
                }
            ]
          }
        JSON
        ClimateControl.modify(VCAP_SERVICES: vcap_services) { example.run }
      end

      it "raises a helpful error message" do
        expect { config.region }.to raise_error(KeyError, /key not found: "aws_region"/)
      end
    end

    context "when the expected credentials object is missing" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
                   "name": "beis-roda-staging-s3-export-download-bucket",
                   "incorrect_credentials_key":{
                      "bucket_name":"exports_bucket",
                      "aws_access_key_id":"KEY_ID",
                      "aws_secret_access_key":"SECRET_KEY"
                   }
                }
            ]
          }
        JSON
        ClimateControl.modify(VCAP_SERVICES: vcap_services) { example.run }
      end

      it "raises a helpful error message" do
        expect { config.region }.to raise_error(/AWS S3 credentials not found/)
      end
    end

    context "when the S3 service has an unexpected name" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
              "aws-s3-bucket":[
                  {
                     "name": "unexpected-s3-service-name",
                     "credentials":{
                        "bucket_name":"exports_bucket",
                        "aws_access_key_id":"KEY_ID",
                        "aws_secret_access_key":"SECRET_KEY"
                     }
                  }
              ]
            }
        JSON
        ClimateControl.modify(VCAP_SERVICES: vcap_services) { example.run }
      end

      it "raises a helpful error message" do
        expect { config.region }.to raise_error(/AWS S3 credentials not found/)
      end
    end

    context "when the aws object is empty" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[]
          }
        JSON
        ClimateControl.modify(VCAP_SERVICES: vcap_services) { example.run }
      end

      it "raises a helpful error message" do
        expect { config.region }.to raise_error(/AWS S3 credentials not found/)
      end
    end

    context "when the expected credentials within VCAP_SERVICES env var are set" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
                   "name": "beis-roda-staging-s3-export-download-bucket-private",
                   "credentials":{
                      "bucket_name":"private_exports_bucket",
                      "aws_access_key_id":"KEY_ID",
                      "aws_secret_access_key":"SECRET_KEY",
                      "aws_region":"eu-west-2"
                   }
                },
                {
                   "name": "beis-roda-staging-s3-export-download-bucket",
                   "credentials":{
                      "bucket_name":"public_exports_bucket",
                      "aws_access_key_id":"KEY_ID",
                      "aws_secret_access_key":"SECRET_KEY",
                      "aws_region":"eu-west-2"
                   }
                }
            ]
          }
        JSON
        ClimateControl.modify(VCAP_SERVICES: vcap_services) { example.run }
      end

      it "returns the key_id" do
        expect(config.key_id).to eq("KEY_ID")
      end

      it "returns the secret_key" do
        expect(config.secret_key).to eq("SECRET_KEY")
      end

      it "returns the region" do
        expect(config.region).to eq("eu-west-2")
      end

      describe "#bucket" do
        context "when initialized with `use_public_bucket: true`" do
          subject(:config) { S3UploaderConfig.new(use_public_bucket: true) }

          it "uses the public S3 bucket" do
            expect(config.bucket).to eq("public_exports_bucket")
          end
        end

        context "when initialized with `use_public_bucket: false`" do
          subject(:config) { S3UploaderConfig.new(use_public_bucket: false) }

          it "uses the private S3 bucket" do
            expect(config.bucket).to eq("private_exports_bucket")
          end
        end
      end
    end
  end
end
