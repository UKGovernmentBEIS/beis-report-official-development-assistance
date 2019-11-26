require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#hierarchy_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the organisation_fund_path" do
        expect(helper.hierarchy_path_for(fund_activity)).to eq(organisation_fund_path(fund, organisation_id: organisation.id))
      end
    end
  end

  describe "#activity_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the fund_activity_path" do
        expect(helper.activity_path_for(fund_activity)).to eq(fund_activity_path(fund_activity, fund_id: fund.id))
      end
    end
  end
end
