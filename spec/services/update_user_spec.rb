require "rails_helper"

RSpec.describe UpdateUser, pending: "To be finished as part of the user edit card" do
  let(:user) { create(:administrator, identifier: "auth0|1234") }

  let(:updated_email) { "new@example.com" }
  let(:updated_name) { "New Name" }

  before(:each) do
    stub_auth0_token_request
  end

  describe "#call" do
    it "returns a successful result" do
      stub_auth0_update_user_request(auth0_identifier: "auth0|1234", email: user.email, name: user.name)

      result = described_class.new(user: user, organisation: build_stubbed(:delivery_partner_organisation)).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    context "when an organisation is provided" do
      it "associates the user to it" do
        stub_auth0_update_user_request(auth0_identifier: "auth0|1234", email: user.email, name: user.name)

        organisation = create(:delivery_partner_organisation)

        described_class.new(
          user: user,
          organisation: organisation
        ).call

        expect(user.reload.organisation).to eql(organisation)
      end
    end

    context "when Auth0 errors" do
      before(:each) do
        stub_auth0_update_user_request_failure(auth0_identifier: "auth0|1234")
        user.email = updated_email
      end

      it "returns a failed result" do
        result = described_class.new(user: user, organisation: build_stubbed(:delivery_partner_organisation)).call
        expect(result.failure?).to eq(true)
      end

      it "does not save the user" do
        expect {
          described_class.new(user: user, organisation: build_stubbed(:delivery_partner_organisation)).call
        }.to_not change { user.reload }
      end

      it "logs a failure message" do
        expect(Rails.logger).to receive(:error)
          .with("Error updating user #{user.email} to Auth0 during UpdateUser with .")

        described_class.new(user: user, organisation: build_stubbed(:delivery_partner_organisation)).call
      end
    end
  end
end
