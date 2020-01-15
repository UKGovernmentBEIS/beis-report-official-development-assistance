require "rails_helper"

RSpec.describe CreateUser do
  let(:user) { build(:administrator) }
  before(:each) do
    stub_auth0_token_request
    stub_welcome_email_delivery
  end

  describe "#call" do
    it "returns a successful result" do
      stub_auth0_create_user_request(email: user.email)

      result = described_class.new(user: user, organisation: build_stubbed(:organisation)).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    it "sends a welcome email to the user" do
      stub_auth0_create_user_request(email: user.email)

      mail_server = double(SendWelcomeEmail)
      expect(SendWelcomeEmail).to receive(:new)
        .with(user: user)
        .and_return(mail_server)

      expect(mail_server).to receive(:call)

      described_class.new(user: user, organisation: build_stubbed(:organisation)).call
    end

    context "when an organisation is provided" do
      it "associates a user to an organisation" do
        stub_auth0_create_user_request(email: user.email)

        organisation = create(:organisation)

        described_class.new(
          user: user,
          organisation: organisation
        ).call

        expect(user.reload.organisation).to eql(organisation)
      end
    end

    context "when Auth0 errors" do
      before(:each) do
        stub_auth0_create_user_request_failure(email: user.email)
      end

      it "returns a failed result" do
        result = described_class.new(user: user, organisation: build_stubbed(:organisation)).call
        expect(result.failure?).to eq(true)
      end

      it "does not save the user" do
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
        expect(User.find_by(email: user.email)).to be_nil
      end

      it "logs a failure message" do
        expect(Rails.logger).to receive(:error)
          .with("Error adding user #{user.email} to Auth0 during CreateUser with .")
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
      end

      it "does not email the user" do
        expect(SendWelcomeEmail).not_to receive(:new)
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
      end
    end
  end
end
