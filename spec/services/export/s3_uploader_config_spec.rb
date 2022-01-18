require "rails_helper"

module Export
  RSpec.describe S3UploaderConfig, wip: true do
    context "when an expected credential is missing from VCAP_SERVICES" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
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
        expect { S3UploaderConfig.region }.to raise_error(KeyError, /key not found: "aws_region"/)
      end
    end

    context "when the expected credentials object is missing" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
                   "incorrect_key":{
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
        expect { S3UploaderConfig.region }.to raise_error(/AWS credentials not found/)
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
        expect { S3UploaderConfig.region }.to raise_error(/AWS credentials not found/)
      end
    end

    context "when the expected credentials within VCAP_SERVICES env var are set" do
      around(:each) do |example|
        vcap_services = <<~JSON
          {
            "aws-s3-bucket":[
                {
                   "credentials":{
                      "bucket_name":"exports_bucket",
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

      it "returns the bucket_name" do
        expect(S3UploaderConfig.bucket).to eq("exports_bucket")
      end

      it "returns the key_id" do
        expect(S3UploaderConfig.key_id).to eq("KEY_ID")
      end

      it "returns the secret_key" do
        expect(S3UploaderConfig.secret_key).to eq("SECRET_KEY")
      end

      it "returns the region" do
        expect(S3UploaderConfig.region).to eq("eu-west-2")
      end
    end
  end
end
