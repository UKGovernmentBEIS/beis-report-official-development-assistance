# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetXmlPresenter do
  describe "#period_start_date" do
    context "when the period_start_date is blank" do
      it "returns nil" do
        budget = build(:budget, period_start_date: "")
        expect(described_class.new(budget).period_start_date).to be_nil
      end
    end

    context "when the period_start_date exists" do
      it "returns an IATI-formatted date" do
        budget = build(:budget, period_start_date: Date.today)
        expect(described_class.new(budget).period_start_date).to eq(Date.today.strftime("%Y-%m-%d"))
      end
    end
  end

  describe "#period_end_date" do
    context "when the period_end_date is blank" do
      it "returns nil" do
        budget = build(:budget, period_end_date: "")
        expect(described_class.new(budget).period_end_date).to be_nil
      end
    end

    context "when the period_end_date exists" do
      it "returns an IATI-formatted date" do
        budget = build(:budget, period_end_date: Date.tomorrow)
        expect(described_class.new(budget).period_end_date).to eq(Date.tomorrow.strftime("%Y-%m-%d"))
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
