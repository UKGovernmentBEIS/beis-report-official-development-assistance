require "rails_helper"

RSpec.describe CreateProgrammeActivity do
  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund_activity) }

  describe "#call" do
    let(:result) { described_class.new(organisation_id: organisation.id, fund_id: fund.id).call }

    it "sets the Organisation" do
      expect(result.organisation).to eq(organisation)
    end

    it "sets the parent Activity to the fund" do
      expect(result.activity).to eq(fund)
    end

    it "sets the initial wizard_status" do
      expect(result.wizard_status).to eq("identifier")
    end

    it "sets the Activity level to 'programme'" do
      expect(result.level).to eq("programme")
    end

    it "sets the funding organisation details" do
      expect(result.funding_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(result.funding_organisation_reference).to eq("GB-GOV-13")
      expect(result.funding_organisation_type).to eq("10")
    end

    it "sets the accountable organisation details" do
      expect(result.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(result.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(result.accountable_organisation_type).to eq("10")
    end
  end
end
