require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }

    it "should not allow an email to be changed" do
      user = create(:administrator, email: "old@example.com")

      user.email = "new@example.com"

      expect(user).to be_invalid
      expect(user.errors[:email]).to eq([I18n.t("activerecord.errors.models.user.attributes.email.cannot_be_changed")])
    end

    it "is not case sensitive" do
      # When a non-lowercase email address exists (Devise lowercases emails on creation so this is for pre-existing addresses)
      user = create(:partner_organisation_user)
      user.update_column(:email, "ForenameMacSurname@ClanMacSurname.org")
      expect(user.email).to eql("ForenameMacSurname@ClanMacSurname.org")

      # And Devise automatically lowercases the address on editing
      user.email = "forenamemacsurname@clanmacsurname.org"

      expect(user).to be_valid
    end
  end

  describe "associations" do
    # This also validates that the relationship is present
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to have_many(:historical_events) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:service_owner?).to(:organisation) }
    it { is_expected.to delegate_method(:delivery_partner?).to(:organisation) }
  end

  it "validates the email format" do
    user = build(:administrator, email: "bogus")

    expect(user).to be_invalid
    expect(user.errors[:email]).to eq(["is not a valid email"])
  end

  describe "password requirements" do
    it "should have a minimum length" do
      user = build(:administrator, password: "Ab3$")

      expect(user.valid?).to be_falsey
      expect(user.errors.messages[:password]).to include("Password is too short (minimum is 15 characters)")
    end

    it "should contain the required characters" do
      user = build(:administrator, password: "AaBbCc123456789")

      expect(user.valid?).to be_falsey
      expect(user.errors.messages[:password]).to include("Password must contain at least one punctuation mark or symbol")

      user.password = "AaBbCc123456789!"

      expect(user.valid?).to be_truthy
    end
  end
end
