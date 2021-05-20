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
  end

  describe "associations" do
    # This also validates that the relationship is present
    it { is_expected.to belong_to(:organisation) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:service_owner?).to(:organisation) }
    it { is_expected.to delegate_method(:delivery_partner?).to(:organisation) }
  end

  describe "#role_name" do
    it "returns the human readable role name of the user" do
      user = described_class.new(role: :administrator)

      expect(user.role_name).to eql "Administrator"
    end
  end
end
