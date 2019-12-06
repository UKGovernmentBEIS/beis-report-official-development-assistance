require "rails_helper"

RSpec.describe TransactionPresenter do
  let(:transaction) { build_stubbed(:transaction, currency: "GBP") }

  describe "#transaction_type" do
    it "returns the I18n string for the transaction_type" do
      expect(described_class.new(transaction).transaction_type).to eq("Incoming Funds")
    end
  end

  describe "#currency" do
    it "returns the I18n string for the currency" do
      expect(described_class.new(transaction).currency).to eq("Pound Sterling")
    end
  end

  describe "#disbursement_channel" do
    it "returns the I18n string for the disbursement_channel" do
      expect(described_class.new(transaction).disbursement_channel).to eq("Money is disbursed through central Ministry of Finance or Treasury")
    end
  end
end
