require "rails_helper"

RSpec.describe Activity, type: :model do
  describe "relations" do
    it { should belong_to(:hierarchy) }
  end

  describe "constraints" do
    it { should validate_uniqueness_of(:identifier) }
  end

  describe "#set_hierarchy_defaults" do
    let(:fund) { build_stubbed(:fund) }

    context "when the hierarchy is unknown" do
      it "should not set any defaults" do
        activity = Activity.new(hierarchy: nil)
        activity.set_hierarchy_defaults
        expect(activity.changed?).to eq(false)
      end
    end

    context "when it's a fund" do
      it "should set the recipient_region to 998" do
        activity = build_stubbed(:activity, hierarchy: fund)
        activity.set_hierarchy_defaults
        expect(activity.recipient_region).to eq("998")
      end

      it "should set the flow to 10" do
        activity = build_stubbed(:activity, hierarchy: fund)
        activity.set_hierarchy_defaults
        expect(activity.flow).to eq("10")
      end

      it "should set the tied_status to 5" do
        activity = build_stubbed(:activity, hierarchy: fund)
        activity.set_hierarchy_defaults
        expect(activity.tied_status).to eq("5")
      end
    end
  end
end
