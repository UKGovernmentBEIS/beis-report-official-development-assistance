require "rails_helper"

RSpec.describe Fund, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "relations" do
    it { should belong_to(:organisation) }
    it { should have_one(:activity) }
  end

  describe ".for_user" do
    subject(:fund) { described_class }

    let(:organisation_1) { create(:organisation) }
    let(:organisation_2) { create(:organisation) }

    let!(:fund_1) { create(:fund, organisation_id: organisation_1.id) }
    let!(:fund_2) { create(:fund, organisation_id: organisation_1.id) }
    let!(:fund_3) { create(:fund, organisation_id: organisation_2.id) }

    context "when the user is in one organisation" do
      let(:user) { create(:user, organisations: [organisation_1]) }

      it "should only return funds belonging to the user's organisation" do
        expect(fund.for_user(user).count).to eq(2)
      end
    end

    context "when the user is in many organisations" do
      let(:user) { create(:user, organisations: [organisation_1, organisation_2]) }

      it "should only return funds belonging to the user's organisations" do
        expect(fund.for_user(user).count).to eq(3)
      end
    end
  end
end
