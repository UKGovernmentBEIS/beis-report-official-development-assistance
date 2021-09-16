require "rails_helper"

RSpec.describe TransactionPresenter do
  let(:transaction) do
    build_stubbed(:actual,
      currency: "GBP",
      date: "2020-06-25",
      value: BigDecimal("110.01"))
  end

  subject { described_class.new(transaction) }

  describe "#date" do
    it "returns a human readable date" do
      expect(subject.date).to eq("25 Jun 2020")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(subject.value).to eq("£110.01")
    end
  end

  describe "#receiving_organisation_name" do
    context "when the organisation is nil" do
      let(:transaction) { build(:actual, receiving_organisation_name: nil) }

      it "returns N/A" do
        expect(subject.receiving_organisation_name).to eq("N/A")
      end
    end

    context "when the organisation is present" do
      let(:organisation_name) { Faker::Company.name }
      let(:transaction) { build(:actual, receiving_organisation_name: organisation_name) }

      it "returns the organisation name" do
        expect(subject.receiving_organisation_name).to eq(organisation_name)
      end
    end
  end
end
