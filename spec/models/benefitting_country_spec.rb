require "spec_helper"

RSpec.describe BenefittingCountry do
  describe ".all" do
    subject { described_class.all }

    it "returns all the countries" do
      expect(subject.count).to eq(177)
    end
  end

  describe ".region_from_country_codes" do
    subject { described_class.region_from_country_codes(codes) }

    context "when the countries share a level 2 region" do
      let(:codes) { ["AO", "GA"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("1028")
      end
    end

    context "when the countries share a level 1 region" do
      let(:codes) { ["AO", "ZW"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("289")
      end
    end

    context "when the countries share a top-level region" do
      let(:codes) { ["ZA", "DZ"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("298")
      end
    end

    context "when the countries don't share a region" do
      let(:codes) { ["ZA", "LB"] }

      it "returns the unspecified region" do
        expect(subject.code).to eq("998")
      end
    end

    context "when there are more than two countries" do
      let(:codes) { ["KG", "TJ", "TM", "AF"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("689")
      end
    end
  end
end
