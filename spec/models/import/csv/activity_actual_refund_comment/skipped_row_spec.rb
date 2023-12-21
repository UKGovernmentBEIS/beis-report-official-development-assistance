require "rails_helper"

RSpec.describe Import::Csv::ActivityActualRefundComment::SkippedRow do
  subject do
    described_class.new(
      double(
        roda_identifier: "VALID-RODA-IDENTIFIER",
        financial_quarter: "2",
        financial_year: "2023"
      )
    )
  end

  describe "#roda_identifier" do
    it "returns the roda identifier from the row" do
      expect(subject.roda_identifier).to eql "VALID-RODA-IDENTIFIER"
    end
  end

  describe "#financial_quarter" do
    it "returns the value from the row" do
      expect(subject.financial_quarter).to eql "2"
    end
  end

  describe "#financial_year" do
    it "returns the value from the row" do
      expect(subject.financial_year).to eql "2023"
    end
  end
end
