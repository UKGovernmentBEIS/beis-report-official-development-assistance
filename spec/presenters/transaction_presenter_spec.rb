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

  describe "#financial_quarter_and_year" do
    it "returns the formatted financial quarter and year e.g. Q1 2020-2021 for the date" do
      transaction.date = Date.new(2020, 6, 1)
      result = described_class.new(transaction).financial_quarter_and_year

      expect(result).to eql "Q1 2020-2021"
    end

    it "returns nil when the transaction has no date" do
      transaction.date = nil
      result = described_class.new(transaction).financial_quarter_and_year

      expect(result).to be_nil
    end
  end
end
