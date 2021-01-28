# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetXmlPresenter do
  describe "#financial_year" do
    context "when the financial_year is blank" do
      it "returns nil for the start and end dates" do
        budget = build(:budget, financial_year: "")
        expect(described_class.new(budget).period_start_date).to be_nil
        expect(described_class.new(budget).period_end_date).to be_nil
      end
    end

    context "when the financial_year exists" do
      it "returns IATI-formatted dates" do
        budget = build(:budget, financial_year: 2020)
        expect(described_class.new(budget).period_start_date).to eq(Date.parse("2020-04-01").strftime("%Y-%m-%d"))
        expect(described_class.new(budget).period_end_date).to eq(Date.parse("2021-03-31").strftime("%Y-%m-%d"))
      end
    end
  end

  describe "#value" do
    it "returns the value as a string" do
      budget = build(:budget, value: 21.01)
      expect(described_class.new(budget).value).to eq("21.01")
    end
  end
end
