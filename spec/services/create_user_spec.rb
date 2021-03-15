require "rails_helper"

RSpec.describe CreateUser do
  let(:user) { build(:administrator) }
  before(:each) do
    stub_auth0_token_request
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

      expect {
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
      }.to have_enqueued_mail(UserMailer, :welcome).with(args: [user])
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
          .with("Error adding user #{user.email} to Auth0 during CreateUser with: The user already exists.")
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
      end

      it "does not email the user" do
        expect(SendWelcomeEmail).not_to receive(:new)
        described_class.new(user: user, organisation: build_stubbed(:organisation)).call
      end

      context "when Auth0 returns an unparseable error message" do
        before do
          stub_auth0_create_user_request_failure(email: user.email, body: "something unparseable")
        end

        it "logs a generic failure message" do
          expect(Rails.logger).to receive(:error)
            .with("Error adding user #{user.email} to Auth0 during CreateUser with: Unknown error")
          described_class.new(user: user, organisation: build_stubbed(:organisation)).call
        end
      end
    end
  end
end
