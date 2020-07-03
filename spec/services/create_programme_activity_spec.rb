require "rails_helper"

RSpec.describe CreateProgrammeActivity do
  let(:organisation) { create(:beis_organisation) }
  let(:fund) { create(:fund_activity) }

  describe "#call" do
    let(:result) { described_class.new(organisation_id: organisation.id, fund_id: fund.id).call }

    it "sets the Organisation" do
      expect(result.organisation).to eq(organisation)
    end

    it "saves the reporting organisation reference" do
      expect(result.reporting_organisation.iati_reference).to eq(organisation.iati_reference)
    end

    it "sets the parent Activity to the fund" do
      expect(result.parent).to eq(fund)
    end

    it "sets the initial form_state" do
      expect(result.form_state).to eq("blank")
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
