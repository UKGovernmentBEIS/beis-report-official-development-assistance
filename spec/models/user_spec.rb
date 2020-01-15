require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe "associations" do
  # This also validates that the relationship is present
  it { is_expected.to belong_to(:organisation).optional(true) }
  end

  describe "#role_name" do
    it "returns the human readable role name of the user" do
      user = User.new(role: :fund_manager)

      expect(user.role_name).to eql "Fund manager"
    end
  end
end
