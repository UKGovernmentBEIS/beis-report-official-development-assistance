require "rails_helper"

class DummyController < ApplicationController; end

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

  describe "Current attributes before action" do
    context "user is not signed in" do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it "does not set Current.user_organisation" do
        controller.send(:set_organisation_list_and_current_organisation)

        expect(Current.user_organisation).to be(nil)
      end
    end

    context "user is signed in" do
      let(:user) { create(:partner_organisation_user) }

      before { allow(controller).to receive(:current_user).and_return(user) }

      it "does not set Current.user_organisation if `current_user_organisation` is not in the session" do
        controller.send(:set_organisation_list_and_current_organisation)

        expect(Current.user_organisation).to be(nil)
        expect(controller.current_user.current_organisation_id).to eql(user.primary_organisation.id)
      end

      it "sets Current.user_organisation if `current_user_organisation` is in the session" do
        session[:current_user_organisation] = "a-fake-id"

        controller.send(:set_organisation_list_and_current_organisation)

        expect(Current.user_organisation).to eql("a-fake-id")
        expect(controller.current_user.current_organisation_id).to eql("a-fake-id")
      end
    end
  end
end
