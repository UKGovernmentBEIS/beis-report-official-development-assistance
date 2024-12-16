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

  describe "before_action" do
    controller DummyController do
      def custom_action
        head 200
      end
    end

    before(:each) do
      routes.draw do
        get "custom_action" => "dummy#custom_action"
      end
    end

    context "user is not signed in" do
      it "does not set Current.user_organisation" do
        get "custom_action"

        expect(Current.user_organisation).to be(nil)
      end
    end

    context "user is signed in" do
      let(:user) { create(:partner_organisation_user) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "does not set Current.user_organisation if `current_user_organisation` is not in the session" do
        get "custom_action"

        expect(Current.user_organisation).to be(nil)
      end

      it "sets Current.user_organisation if `current_user_organisation` is in the session" do
        id = SecureRandom.uuid
        session[:current_user_organisation] = id

        get "custom_action"

        expect(Current.user_organisation).to be(id)
      end
    end
  end
end
