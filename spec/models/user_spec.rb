require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe "associations" do
    # This also validates that the relationship is present
    it { is_expected.to belong_to(:organisation) }
  end

  describe "#role_name" do
    it "returns the human readable role name of the user" do
      user = described_class.new(role: :administrator)

      expect(user.role_name).to eql "Administrator"
    end
  end

  describe "#service_owner?" do
    context "when the user organisation is a service owner" do
      it "returns true" do
        organisation = build_stubbed(:organisation, service_owner: true)
        result = described_class.new(organisation: organisation).service_owner?
        expect(result).to be true
      end
    end

    context "when the user organisation is NOT a service owner" do
      it "returns false" do
        organisation = build_stubbed(:organisation, service_owner: false)
        result = described_class.new(organisation: organisation).service_owner?
        expect(result).to be false
      end
    end
  end

  describe "#delivery_partner?" do
    context "when the user organisation is a service owner" do
      it "returns false" do
        organisation = build_stubbed(:organisation, service_owner: true)
        result = described_class.new(organisation: organisation).delivery_partner?
        expect(result).to be false
      end
    end

    context "when the user organisation is NOT a service owner" do
      it "returns true" do
        organisation = build_stubbed(:organisation, service_owner: false)
        result = described_class.new(organisation: organisation).delivery_partner?
        expect(result).to be true
      end
    end
  end
end
