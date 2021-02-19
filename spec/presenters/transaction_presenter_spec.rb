require "rails_helper"

RSpec.describe TransactionPresenter do
  let(:transaction) { build_stubbed(:transaction, currency: "GBP") }

  describe "#date" do
    it "returns a human readable date" do
      transaction.date = "2020-06-25"
      expect(described_class.new(transaction).date).to eq("25 Jun 2020")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(transaction).value).to eq("£110.01")
    end
  end
end
