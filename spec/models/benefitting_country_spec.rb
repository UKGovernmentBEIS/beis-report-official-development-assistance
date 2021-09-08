require "spec_helper"

RSpec.describe BenefittingCountry do
  let(:region) { BenefittingCountry::Region::Level.new(code: 1, name: "Region") }
  let(:subregion1) { BenefittingCountry::Region::Level.new(code: 2, name: "Sub-region 1") }
  let(:subregion2) { BenefittingCountry::Region::Level.new(code: 3, name: "Sub-region 2") }

  let(:africa) { BenefittingCountry::Region.new(name: "Africa, regional", code: "298", level: region) }
  let(:south_of_sahara) { BenefittingCountry::Region.new(name: "South of Sahara, regional", code: "289", level: subregion1) }
  let(:middle_africa) { BenefittingCountry::Region.new(name: "Middle Africa, regional", code: "1028", level: subregion2) }
  let(:eastern_africa) { BenefittingCountry::Region.new(name: "Eastern Africa, regional", code: "1027", level: subregion2) }
  let(:southern_africa) { BenefittingCountry::Region.new(name: "Southern Africa, regional", code: "102", level: subregion2) }
  let(:north_of_sahara) { BenefittingCountry::Region.new(name: "North of Sahara, regional", code: "189", level: subregion2) }
  let(:asia) { BenefittingCountry::Region.new(name: "Asia, regional", code: "798", level: region) }
  let(:middle_east) { BenefittingCountry::Region.new(name: "Middle East, regional", code: "589", level: subregion1) }

  let(:countries) do
    [
      BenefittingCountry.new(
        code: "AO",
        name: "Angola",
        regions: [
          africa,
          south_of_sahara,
          middle_africa,
        ]
      ),
      BenefittingCountry.new(
        code: "GA",
        name: "Gabon",
        regions: [
          africa,
          south_of_sahara,
          middle_africa,
        ]
      ),
      BenefittingCountry.new(
        code: "ZW",
        name: "Zimbabwe",
        regions: [
          africa,
          south_of_sahara,
          eastern_africa,
        ]
      ),
      BenefittingCountry.new(
        code: "ZA",
        name: "South Africa",
        regions: [
          africa,
          south_of_sahara,
          eastern_africa,
        ]
      ),
      BenefittingCountry.new(
        code: "DZ",
        name: "Algeria",
        regions: [
          africa,
          north_of_sahara,
        ]
      ),
      BenefittingCountry.new(
        code: "LB",
        name: "Lebanon",
        regions: [
          asia,
          middle_east,
        ]
      ),
    ]
  end

  before do
    allow(described_class).to receive(:all).and_return(countries)
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
      let(:codes) { ["AO", "GA", "AO", "ZW", "DZ"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("298")
      end
    end
  end
end
