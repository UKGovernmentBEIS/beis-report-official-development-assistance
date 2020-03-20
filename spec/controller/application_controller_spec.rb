require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  describe "#request_ip" do
    it "returns the anonymized v4 IP with the last octet zero padded" do
      allow_any_instance_of(ActionController::TestRequest)
        .to receive(:ip)
        .and_return("1.2.3.4")
      expect(controller.request_ip).to eql("1.2.3.0")
    end

    context "when the v4 IP is at the max range" do
      it "returns the anonymized v4 IP with the last octet zero padded" do
        allow_any_instance_of(ActionController::TestRequest)
          .to receive(:ip)
          .and_return("255.255.255.255")
        expect(controller.request_ip).to eql("255.255.255.0")
      end
    end

    context "when the IP address is v6" do
      it "returns the anonymized v6 IP with the last octet removed" do
        allow_any_instance_of(ActionController::TestRequest)
          .to receive(:ip)
          .and_return("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
        expect(controller.request_ip).to eql("2001:db8:85a3::")
      end
    end
  end
end
