require "rails_helper"

RSpec.describe Activity, type: :model do
  describe "relations" do
    it { should belong_to(:hierarchy) }
  end

  describe "constraints" do
    it { should validate_uniqueness_of(:identifier) }
  end

  describe "validations" do
    context "when recipient_region is blank" do
      it "raises an error" do
        activity = build(:activity, recipient_region: nil, wizard_status: :country)
        activity.valid?
        expect(activity.errors.messages)
          .to include(recipient_region: ["Recipient region can't be blank"])
      end
    end

    context "when flow is blank" do
      it "raises an error" do
        activity = build(:activity, flow: nil, wizard_status: :flow)
        activity.valid?
        expect(activity.errors.messages)
          .to include(flow: ["Flow can't be blank"])
      end
    end

    context "when tied_status is blank" do
      it "raises an error" do
        activity = build(:activity, tied_status: nil, wizard_status: :tied_status)
        activity.valid?
        expect(activity.errors.messages)
          .to include(tied_status: ["Tied status can't be blank"])
      end
    end
  end
end
