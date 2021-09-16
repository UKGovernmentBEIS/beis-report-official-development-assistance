RSpec.describe BenefittingRegion do
  let(:region) { BenefittingRegion::Level.new(code: 1, name: "Region") }
  let(:subregion1) { BenefittingRegion::Level.new(code: 2, name: "Sub-region 1") }
  let(:subregion2) { BenefittingRegion::Level.new(code: 3, name: "Sub-region 2") }

  let(:africa) { BenefittingRegion.new(name: "Africa, regional", code: "298", level: region) }
  let(:south_of_sahara) { BenefittingRegion.new(name: "South of Sahara, regional", code: "289", level: subregion1) }
  let(:middle_africa) { BenefittingRegion.new(name: "Middle Africa, regional", code: "1028", level: subregion2) }

  let(:regions) { [africa, south_of_sahara, middle_africa] }
  let(:region_levels) { [region, subregion1, subregion2] }

  before do
    allow(described_class).to receive(:all).and_return(regions)
    allow(described_class::Level).to receive(:all).and_return(region_levels)
  end

  describe ".all_for_level" do
    subject { described_class.all_for_level_code(code) }

    context "with level 3 (sub region 3)" do
      let(:code) { 3 }

      it "returns all the regions for a given level" do
        expect(subject.count).to eql 1
        expect(subject).not_to include africa
        expect(subject).not_to include south_of_sahara
        expect(subject).to include middle_africa
      end
    end
  end
end
