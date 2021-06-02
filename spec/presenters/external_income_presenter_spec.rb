require "rails_helper"

RSpec.describe ExternalIncomePresenter do
  let(:external_income) { build(:external_income) }
  subject { described_class.new(external_income) }

  describe "#amount" do
    before { external_income.amount = 800_000.1 }

    it "returns the amount in pounds and pence" do
      expect(subject.amount).to eq("£800,000.10")
    end
  end

  describe "#oda_funding" do
    context "when true" do
      before { external_income.oda_funding = true }

      it "returns yes" do
        expect(subject.oda_funding).to eq("Yes")
      end
    end

    context "when false" do
      before { external_income.oda_funding = false }

      it "returns no" do
        expect(subject.oda_funding).to eq("No")
      end
    end
  end
end
