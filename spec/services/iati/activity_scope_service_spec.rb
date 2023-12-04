require "rails_helper"

RSpec.describe Iati::ActivityScopeService do
  describe "#call" do
    context "when there is a single benefitting country in one region" do
      it "returns the IATI code for national: 4" do
        country_codes = ["DZ"]

        expect(described_class.new(country_codes).call).to eql 4
      end
    end

    context "when there are multiple benefitting countries in one region" do
      it "returns the IATI code for regional: 2" do
        country_codes = ["DZ", "MA", "EG"]

        expect(described_class.new(country_codes).call).to eql 2
      end
    end

    context "when there are multiple benefitting countries across multiple regions" do
      it "returns the IATI code for multi-national: 3" do
        country_codes = ["DZ", "SV", "MY"]

        expect(described_class.new(country_codes).call).to eql 3
      end
    end

    context "when the activity has no benefitting countries" do
      it "returns false" do
        country_codes = []

        expect(described_class.new(country_codes).call).to eql false
      end
    end

    context "when the activity benefitting countries is nil" do
      it "returns false" do
        country_codes = nil

        expect(described_class.new(country_codes).call).to eql false
      end
    end
  end
end
