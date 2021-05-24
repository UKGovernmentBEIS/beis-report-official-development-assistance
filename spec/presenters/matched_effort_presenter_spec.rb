require "rails_helper"

RSpec.describe MatchedEffortPresenter do
  let(:matched_effort) { build(:matched_effort) }
  subject { described_class.new(matched_effort) }

  describe "#funding_type" do
    context "when funding type is nil" do
      before { matched_effort.funding_type = nil }

      it "returns nil" do
        expect(subject.funding_type).to be_nil
      end
    end

    context "when funding type is specified" do
      before { matched_effort.funding_type = "reciprocal" }

      it "returns the name from the codelist" do
        expect(subject.funding_type).to eq("Reciprocal")
      end
    end
  end

  describe "#category" do
    context "when category is nil" do
      before { matched_effort.category = nil }

      it "returns nil" do
        expect(subject.category).to be_nil
      end
    end

    context "when category is specified" do
      before { matched_effort.category = "access_to_data" }

      it "returns the name from the codelist" do
        expect(subject.category).to eq("Access to data")
      end
    end
  end

  describe "#committed_amount" do
    before { matched_effort.committed_amount = 100_000.99 }

    it "returns the amount in pounds and pence" do
      expect(subject.committed_amount).to eq("£100,000.99")
    end
  end
end
