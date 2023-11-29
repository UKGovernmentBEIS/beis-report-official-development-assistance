require "rails_helper"

RSpec.describe Fund do
  let(:newton_code) { 1 }
  let(:gcrf_code) { 2 }
  let(:ispf_code) { 4 }

  describe ".initialize" do
    it "initializes successfully when the code exists" do
      fund = described_class.new(newton_code)

      expect(fund.name).to eq("Newton Fund")
      expect(fund.id).to eq(newton_code)
    end

    it "initializes successfully when the code was provided as a string" do
      fund = described_class.new(newton_code.to_s)

      expect(fund.name).to eq("Newton Fund")
      expect(fund.id).to eq(newton_code)
    end

    it "raises and error when the code does not exist" do
      expect { described_class.new(99) }.to raise_error("Fund::InvalidFund")
      expect { described_class.new("99") }.to raise_error("Fund::InvalidFund")
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

      it "should return 'NF' as the short name" do
        expect(fund.short_name).to eq("NF")
      end
    end

    context "when the associated fund is GCRF" do
      let(:activity) { build(:fund_activity, :gcrf) }

      it "should return 'GCRF' as the name" do
        expect(fund.name).to eq("Global Challenges Research Fund")
      end

      it "should return '2' as the ID" do
        expect(fund.id).to eq(2)
      end

      it "should return 'GCRF' as the short name" do
        expect(fund.short_name).to eq("GCRF")
      end
    end

    context "when the activity is not a fund" do
      let(:activity) { build(:project_activity) }

      it "should raise an error" do
        expect { fund }.to raise_error("Fund::InvalidActivity")
      end
    end

    context "when the fund does not have the expected fragment" do
      let(:activity) { build(:fund_activity, roda_identifier: "FOO") }

      it "should raise an error" do
        expect { fund }.to raise_error("Fund::InvalidFund")
      end
    end
  end

  describe ".all" do
    it "returns a Fund for every entry in the 'fund_types' codelist" do
      codelist = Codelist.new(type: "fund_types", source: "beis")

      funds = described_class.all
      expect(funds.size).to eq(codelist.list.size)

      ids = funds.map(&:id)
      expect(ids).to eq(codelist.values_for("code"))
    end
  end

  describe "#gcrf?" do
    let(:fund) { described_class.new(id) }
    subject { fund.gcrf? }

    context "when the fund is GCRF" do
      let(:id) { gcrf_code }

      it { is_expected.to be(true) }
    end

    context "when the fund is not GCRF" do
      let(:id) { newton_code }

      it { is_expected.to be(false) }
    end
  end

  describe "#newton?" do
    let(:fund) { described_class.new(id) }
    subject { fund.newton? }

    context "when the fund is Newton" do
      let(:id) { newton_code }

      it { is_expected.to be(true) }
    end

    context "when the fund is not Newton" do
      let(:id) { gcrf_code }

      it { is_expected.to be(false) }
    end
  end

  describe "#ispf?" do
    let(:fund) { described_class.new(id) }
    subject { fund.ispf? }

    context "when the fund is ISPF" do
      let(:id) { ispf_code }

      it { is_expected.to be(true) }
    end

    context "when the fund is not ISPF" do
      let(:id) { gcrf_code }

      it { is_expected.to be(false) }
    end
  end

  describe "#==" do
    it "is true when the instances have the same id" do
      instance_1 = described_class.new(newton_code)
      instance_2 = described_class.new(newton_code)

      expect(instance_1 == instance_2).to be_truthy
    end
  end

  describe "#activity" do
    let(:fund) { described_class.new(id) }

    context "when the fund is GCRF" do
      let(:id) { gcrf_code }

      it "returns the GCRF fund-level Activity for the current Fund" do
        fund_activity = create(:fund_activity, :gcrf)

        expect(fund.activity).to eq(fund_activity)
      end
    end

    context "when the fund is Newton Fund" do
      let(:id) { newton_code }

      it "returns the Newton fund-level Activity for the current Fund" do
        fund_activity = create(:fund_activity, :newton)

        expect(fund.activity).to eq(fund_activity)
      end
    end
  end
end
