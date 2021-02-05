require "rails_helper"

RSpec.describe Fund do
  describe ".initialize" do
    it "initializes successfully when the code exists" do
      fund = described_class.new(1)

      expect(fund.name).to eq("Newton Fund")
      expect(fund.id).to eq(1)
    end

    it "raises and error when the code does not exist" do
      expect { described_class.new(99) }.to raise_error("Fund::InvalidFund")
    end
  end

  describe ".from_activity" do
    let(:fund) { described_class.from_activity(activity) }

    context "when the associated fund is Newton" do
      let(:activity) { build(:fund_activity, :newton) }

      it "should return 'Newton Fund' as the name" do
        expect(fund.name).to eq("Newton Fund")
      end

      it "should return '1' as the ID" do
        expect(fund.id).to eq(1)
      end
    end

    context "when the associated fund is GCRF" do
      let(:activity) { build(:fund_activity, :gcrf) }

      it "should return 'GCRF' as the name" do
        expect(fund.name).to eq("GCRF")
      end

      it "should return '1' as the ID" do
        expect(fund.id).to eq(2)
      end
    end

    context "when the activity is not a fund" do
      let(:activity) { build(:project_activity) }

      it "should raise an error" do
        expect { fund }.to raise_error("Fund::InvalidActivity")
      end
    end

    context "when the fund does not have the expected fragment" do
      let(:activity) { build(:fund_activity, roda_identifier_fragment: "FOO") }

      it "should raise an error" do
        expect { fund }.to raise_error("Fund::InvalidFund")
      end
    end
  end
end
