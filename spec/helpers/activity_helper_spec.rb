require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#hierarchy_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the organisation_fund_path" do
        expect(helper.hierarchy_path_for(activity: fund_activity))
          .to eq(organisation_fund_path(organisation.id, fund))
      end
    end
  end

  describe "#activity_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the fund_activity_path" do
        expect(helper.activity_path_for(activity: fund_activity))
          .to eq(fund_activity_path(fund, fund_activity))
      end
    end
  end

  describe "#edit_activity_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the edit path for the first step by default" do
        expect(
          helper.edit_activity_path_for(activity: fund_activity)
        ).to eq(
          fund_activity_step_path(
            fund_id: fund,
            activity_id: fund_activity,
            id: :identifier
          )
        )
      end

      it "returns the edit path for the given step" do
        expect(
          helper.edit_activity_path_for(activity: fund_activity, step: :sector)
        ).to eq(
          fund_activity_step_path(
            fund_id: fund,
            activity_id: fund_activity,
            id: :sector
          )
        )
      end
    end
  end
end
