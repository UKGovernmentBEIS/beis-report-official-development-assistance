# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportPresenter do
  describe "#state" do
    it "returns the string for the state" do
      report = build(:report, state: "inactive")
      result = described_class.new(report).state
      expect(result).to eql("Inactive")
    end
  end

  describe "#deadline" do
    it "returns the formatted date for the deadline" do
      report = build(:report, deadline: Date.today)
      result = described_class.new(report).deadline
      expect(result).to eql I18n.l(Date.today)
    end
  end

  describe "#financial_quarter_and_year" do
    it "returns the formatted financial quarter and year e.g. Q1 2020-2021" do
      report = build(:report, financial_quarter: 1, financial_year: 2020)
      result = described_class.new(report).financial_quarter_and_year

      expect(result).to eql "Q1 2020-2021"
    end

    it "returns nil when the report has no financial quarter or year" do
      report = build(:report, financial_quarter: nil, financial_year: nil)
      result = described_class.new(report).financial_quarter_and_year

      expect(result).to be_nil
    end
  end
end
