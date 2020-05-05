require "rails_helper"

RSpec.describe CreateFundActivity do
  let(:organisation) { create(:beis_organisation) }

  describe "#call" do
    let(:result) { described_class.new(organisation_id: organisation.id).call }

    it "sets the Organisation" do
      expect(result.organisation).to eq(organisation)
    end

    it "saves the reporting organisation reference" do
      expect(result.reporting_organisation.iati_reference).to eq(organisation.iati_reference)
    end

    it "sets the initial form_state" do
      expect(result.form_state).to eq("blank")
    end

    it "sets the activity level to 'fund'" do
      expect(result.level).to eq("fund")
    end

    it "sets the funding organisation details" do
      expect(result.funding_organisation_name).to eq("HM Treasury")
      expect(result.funding_organisation_reference).to eq("GB-GOV-2")
      expect(result.funding_organisation_type).to eq("10")
    end

    it "sets the accountable organisation details" do
      expect(result.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(result.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(result.accountable_organisation_type).to eq("10")
    end

    it "sets the extending organisation to BEIS" do
      expect(result.extending_organisation).to eql organisation
    end
  end
end
