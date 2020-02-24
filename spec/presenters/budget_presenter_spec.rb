require "rails_helper"

RSpec.describe BudgetPresenter do
  let(:budget) { build_stubbed(:budget, period_start_date: "2020-02-02", period_end_date: "2021-01-01", value: "20") }

  describe "#budget_type" do
    it "returns the I18n string for the budget_type" do
      expect(described_class.new(budget).budget_type).to eq("Original")
    end
  end

  describe "#status" do
    it "returns the I18n string for the status" do
      expect(described_class.new(budget).status).to eq("Indicative")
    end
  end

  describe "#period_start_date" do
    it "returns the localised date for the period_start_date" do
      expect(described_class.new(budget).period_start_date).to eq("2 Feb 2020")
    end
  end

  describe "#period_end_date" do
    it "returns the localised date for the period_end_date" do
      expect(described_class.new(budget).period_end_date).to eq("1 Jan 2021")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(budget).value).to eq("£20.00")
    end
  end
end
