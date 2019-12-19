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
      subject { build(:activity, recipient_region: nil, wizard_status: :country) }
      it { should validate_presence_of(:recipient_region) }
    end

    context "when flow is blank" do
      subject { build(:activity, flow: nil, wizard_status: :flow) }
      it { should validate_presence_of(:flow) }
    end

    context "when tied_status is blank" do
      subject { build(:activity, tied_status: nil, wizard_status: :tied_status) } 
      it { should validate_presence_of(:tied_status) }
    end
  end
end
