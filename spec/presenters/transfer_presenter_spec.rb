require "rails_helper"

RSpec.describe TransferPresenter do
  let(:transfer) { build_stubbed(:transfer, value: "110.01", financial_year: 2020, financial_quarter: 1) }

  describe "#financial_quarter_and_year" do
    it "returns the financial quarter and year" do
      expect(described_class.new(transfer).financial_quarter_and_year).to eq("Q1 2020-2021")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(transfer).value).to eq("£110.01")
    end
  end
end
