RSpec.describe TransactionHelper do
  let(:organisation) { create(:organisation) }

  describe "#create_transaction_path_for" do
    context "when the hierarchy is a Fund" do
      it "returns the fund_transactions_path" do
        fund = create(:fund, organisation: organisation)
        expect(helper.create_transaction_path_for(hierarchy: fund)).to eq(
          fund_transactions_path(fund)
        )
      end
    end

    context "when the hierarchy is a Programme" do
      it "returns the programme_transactions_path" do
        fund = create(:fund, organisation: organisation)
        programme = create(:programme, fund: fund)
        expect(helper.create_transaction_path_for(hierarchy: programme)).to eq(
          programme_transactions_path(programme)
        )
      end
    end
  end
end
