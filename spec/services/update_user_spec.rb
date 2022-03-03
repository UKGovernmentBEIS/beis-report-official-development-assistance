require "rails_helper"

RSpec.describe UpdateUser do
  let(:user) { create(:administrator) }

  let(:updated_email) { "new@example.com" }
  let(:updated_name) { "New Name" }

  describe "#call" do
    it "returns a successful result" do
      result = described_class.new(user: user, organisation: build_stubbed(:delivery_partner_organisation)).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    context "when an organisation is provided" do
      it "associates the user to it" do
        organisation = create(:delivery_partner_organisation)

        described_class.new(
          user: user,
          organisation: organisation
        ).call

        expect(user.reload.organisation).to eql(organisation)
      end
    end

    context "when reset MFA is requested" do
      it "resets the user's mobile number and its confirmation time" do
        described_class.new(
          user: user,
          organisation: user.organisation,
          reset_mfa: true
        ).call

        expect(user.reload.mobile_number).to be_nil
        expect(user.mobile_number_confirmed_at).to be_nil
      end
    end
  end
end
