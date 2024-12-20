require "rails_helper"

RSpec.describe CreateUser do
  let(:user) { build(:administrator, :new_user) }

  describe "#call" do
    it "returns a successful result" do
      result = CreateUser.new(user: user, organisation: user.organisation).call

      expect(result.success?).to be(true)
    end

    it "sends a welcome email to the user" do
      expect {
        CreateUser.new(user: user, organisation: user.organisation).call
      }.to have_enqueued_mail(UserMailer, :welcome).with(user)
    end

    it "creates a default password, known to no-one" do
      CreateUser.new(user: user, organisation: user.organisation).call
      expect(User.last.encrypted_password).not_to be_blank
    end

    context "when an organisation is provided" do
      it "associates a user to an organisation" do
        organisation = create(:partner_organisation)

        CreateUser.new(
          user: user,
          organisation: organisation
        ).call

        expect(user.reload.organisation).to eql(organisation)
      end
    end

    context "when additional organisations are provided" do
      it "associates the additional organsations to it" do
        organisation = create(:partner_organisation)
        org1 = create(:partner_organisation)
        org2 = create(:partner_organisation)

        described_class.new(
          user: user,
          organisation: organisation,
          additional_organisations: [org1, org2]
        ).call

        expect(user.reload.additional_organisations).to include(org1, org2)
      end
    end
  end
end
