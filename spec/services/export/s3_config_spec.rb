require "rails_helper"

module Export
  RSpec.describe S3Config do
    subject(:config) { S3Config.new }

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is not present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: nil) { example.run }
      end

      it "raises a helpful error message" do
        expect { config.region }.to raise_error(/AWS S3 credentials not found/)
      end
    end

    context "when the EXPORT_DOWNLOAD_S3_BUCKET env var is present" do
      around(:each) do |example|
        ClimateControl.modify(EXPORT_DOWNLOAD_S3_BUCKET: "dsit-exports-bucket") { example.run }
      end

      describe "#region" do
        it "returns the hardcoded region 'eu-west-2'" do
          expect(config.region).to eq("eu-west-2")
        end
      end

      describe "#bucket" do
        it "returns the bucket name from the env var" do
          expect(config.bucket).to eq("dsit-exports-bucket")
        end
      end
    end
  end
end
