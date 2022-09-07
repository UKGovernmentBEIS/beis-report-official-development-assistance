require "rails_helper"

RSpec.describe CreateUser do
  let(:user) { build(:administrator, :new_user) }

  describe "#call" do
    it "returns a successful result" do
      result = CreateUser.new(user: user, organisation: build_stubbed(:partner_organisation)).call

      expect(result.success?).to eq(true)
    end

    it "sends a welcome email to the user" do
      expect {
        CreateUser.new(user: user, organisation: build_stubbed(:partner_organisation)).call
      }.to have_enqueued_mail(UserMailer, :welcome).with(user)
    end

    it "creates a default password, known to no-one" do
      CreateUser.new(user: user, organisation: build_stubbed(:partner_organisation)).call
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
  end
end
