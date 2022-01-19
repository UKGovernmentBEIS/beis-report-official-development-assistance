require "spec_helper"

RSpec.describe BenefittingCountry do
  let(:region) { BenefittingRegion::Level.new(code: 1, name: "Region") }
  let(:subregion1) { BenefittingRegion::Level.new(code: 2, name: "Sub-region 1") }
  let(:subregion2) { BenefittingRegion::Level.new(code: 3, name: "Sub-region 2") }

  let(:africa) { BenefittingRegion.new(name: "Africa, regional", code: "298", level: region) }
  let(:south_of_sahara) { BenefittingRegion.new(name: "South of Sahara, regional", code: "289", level: subregion1) }
  let(:middle_africa) { BenefittingRegion.new(name: "Middle Africa, regional", code: "1028", level: subregion2) }
  let(:eastern_africa) { BenefittingRegion.new(name: "Eastern Africa, regional", code: "1027", level: subregion2) }
  let(:southern_africa) { BenefittingRegion.new(name: "Southern Africa, regional", code: "102", level: subregion2) }
  let(:north_of_sahara) { BenefittingRegion.new(name: "North of Sahara, regional", code: "189", level: subregion2) }
  let(:asia) { BenefittingRegion.new(name: "Asia, regional", code: "798", level: region) }
  let(:middle_east) { BenefittingRegion.new(name: "Middle East, regional", code: "589", level: subregion1) }

  let(:graduated_countries) do
    [
      BenefittingCountry.new(
        code: "SC",
        name: "Seychelles",
        graduated: true,
        regions: [
          africa,
          south_of_sahara,
          eastern_africa
        ]
      )
    ]
  end

  let(:non_graduated_countries) do
    [
      BenefittingCountry.new(
        code: "AO",
        name: "Angola",
        graduated: false,
        regions: [
          africa,
          south_of_sahara,
          middle_africa
        ]
      ),
      BenefittingCountry.new(
        code: "GA",
        name: "Gabon",
        graduated: false,
        regions: [
          africa,
          south_of_sahara,
          middle_africa
        ]
      ),
      BenefittingCountry.new(
        code: "ZW",
        name: "Zimbabwe",
        graduated: false,
        regions: [
          africa,
          south_of_sahara,
          eastern_africa
        ]
      ),
      BenefittingCountry.new(
        code: "ZA",
        name: "South Africa",
        graduated: false,
        regions: [
          africa,
          south_of_sahara,
          eastern_africa
        ]
      ),
      BenefittingCountry.new(
        code: "DZ",
        name: "Algeria",
        graduated: false,
        regions: [
          africa,
          north_of_sahara
        ]
      ),
      BenefittingCountry.new(
        code: "LB",
        name: "Lebanon",
        graduated: false,
        regions: [
          asia,
          middle_east
        ]
      )
    ]
  end

  let(:countries) { non_graduated_countries + graduated_countries }

  before do
    allow(described_class).to receive(:all).and_return(countries)
    allow(described_class).to receive(:non_graduated).and_return(non_graduated_countries)
  end

  describe ".all" do
    subject { described_class.all }

    it "includes graduated and non graduated countries" do
      expect(subject).to match countries
    end
  end

  describe ".non_graduated" do
    subject { described_class.non_graduated }

    it "does not include graduated countries" do
      expect(subject).not_to include non_graduated_countries
    end
  end

  describe ".non_graduated_for_region" do
    subject { described_class.non_graduated_for_region(region) }

    let(:region) { middle_africa }

    it "returns all BenefittingCountry for a given region" do
      country_in_region = BenefittingCountry.find_non_graduated_country_by_code("AO")
      country_not_in_region = BenefittingCountry.find_non_graduated_country_by_code("LB")

      expect(subject.count).to eql 2
      expect(subject).to include country_in_region
      expect(subject).not_to include country_not_in_region
    end
  end

  describe ".find_non_graduated_country_by_code" do
    subject { described_class.find_non_graduated_country_by_code(code) }

    context "when the code is of a graduated country" do
      let(:code) { "SC" }

      it "returns nil when the code is that of a graduated country" do
        expect(subject).to be_nil
      end
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
      let(:codes) { ["AO", "GA", "AO", "ZW", "DZ"] }

      it "gets the most specific region" do
        expect(subject.code).to eq("298")
      end
    end
  end
end
