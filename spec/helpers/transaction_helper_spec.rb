require "rails_helper"

RSpec.describe TransactionHelper, type: :helper do
  describe "#hierarchy_for" do
    context "when the hierarchy_type is Fund" do
      it "returns the Fund" do
        fund = create(:fund)
        transaction = build(:transaction, hierarchy: fund)
        expect(helper.hierarchy_for(transaction: transaction)).to eq(fund)
      end
    end
  end

  describe "#transaction_hierarchy_path_for" do
    context "when the hierarchy_type is Fund" do
      it "returns the Fund show page" do
        fund = create(:fund)
        transaction = build(:transaction, hierarchy: fund)
        expect(helper.transaction_hierarchy_path_for(transaction: transaction))
          .to eq(organisation_fund_path(fund.organisation, fund))
      end
    end
  end

  describe "#hierarchy_object_path" do
    context "when the hierarchy_type is Fund" do
      it "returns the Fund show page" do
        fund = create(:fund)
        expect(helper.hierarchy_object_path(hierarchy: fund))
          .to eq(organisation_fund_path(fund.organisation, fund))
      end
    end
  end
end
