require "rails_helper"

RSpec.describe UpdateUser do
  let(:user) { create(:user, identifier: "auth0|1234") }

  let(:updated_email) { "new@example.com" }
  let(:updated_name) { "New Name" }

  before(:each) do
    stub_auth0_token_request
  end

  describe "#call" do
    it "returns a successful result" do
      stub_auth0_update_user_request(auth0_identifier: "auth0|1234", email: user.email, name: user.name)

      result = described_class.new(user: user).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    context "when organisations are provided" do
      it "associates them to the user" do
        stub_auth0_update_user_request(auth0_identifier: "auth0|1234", email: user.email, name: user.name)

        first_organisation = create(:organisation)
        second_organisation = create(:organisation)

        described_class.new(
          user: user,
          organisations: [first_organisation, second_organisation]
        ).call

        expect(user.reload.organisations).to include(first_organisation)
        expect(user.reload.organisations).to include(second_organisation)
      end
    end

    context "when Auth0 errors" do
      before(:each) do
        stub_auth0_update_user_request_failure(auth0_identifier: "auth0|1234")
        user.email = updated_email
      end

      it "returns a failed result" do
        result = described_class.new(user: user).call
        expect(result.failure?).to eq(true)
      end

      it "does not save the user" do
        expect { described_class.new(user: user).call }.to_not change { user.reload }
      end

      it "logs a failure message" do
        expect(Rails.logger).to receive(:error)
          .with("Error updating user #{user.email} to Auth0 during UpdateUser with .")

        described_class.new(user: user).call
      end
    end
  end
end
