require "rails_helper"

RSpec.describe BudgetPresenter do
  let(:budget) { build_stubbed(:budget, financial_year: 2020, value: "20") }

  describe "#iati_type" do
    it "returns the name of the IATI budget type" do
      expect(described_class.new(budget).iati_type).to eq("Original")
    end
  end

  describe "#iati_status" do
    it "returns the name of the IATI budete status" do
      expect(described_class.new(budget).iati_status).to eq("Committed")
    end
  end

  describe "#period_start_date" do
    it "returns the localised date for the period_start_date" do
      expect(described_class.new(budget).period_start_date).to eq("1 Apr 2020")
    end
  end

  describe "#period_end_date" do
    it "returns the localised date for the period_end_date" do
      expect(described_class.new(budget).period_end_date).to eq("31 Mar 2021")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(budget).value).to eq("£20.00")
    end
  end

  describe "#currency" do
    it "returns the I18n string for the currency" do
      expect(described_class.new(budget).currency).to eq("Pound Sterling")
    end
  end
end
