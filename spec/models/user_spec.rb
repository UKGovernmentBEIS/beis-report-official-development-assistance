require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe "associations" do
    it { should have_and_belong_to_many(:organisations) }
  end

  describe "#role_name" do
    it "returns the human readable role name of the user" do
      user = User.new(role: :fund_manager)

      expect(user.role_name).to eql "Fund manager"
    end
  end
end
