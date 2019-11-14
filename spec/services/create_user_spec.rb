require "rails_helper"

RSpec.describe CreateUser do
  let(:user) { build(:user, identifier: nil) }
  before(:each) do
    stub_auth0_token_request
  end

  describe "#call" do
    it "returns a successful result" do
      stub_auth0_create_user_request(email: user.email)

      result = described_class.new(user: user).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    context "when Auth0 errors" do
      before(:each) do
        stub_auth0_create_user_request_failure(user.email)
      end

      it "returns a failed result" do
        result = described_class.new(user: user).call
        expect(result.failure?).to eq(true)
      end

      it "does not save the user" do
        described_class.new(user: user).call
        expect(User.find_by(email: user.email)).to be_nil
      end

      it "logs a failure message" do
        expect(Rails.logger).to receive(:error)
          .with("Error adding user #{user.email} to Auth0 during CreateUser with .")
        described_class.new(user: user).call
      end
    end
  end
end
