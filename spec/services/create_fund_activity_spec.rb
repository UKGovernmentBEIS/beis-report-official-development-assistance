require "rails_helper"

RSpec.describe CreateFundActivity do
  let(:organisation) { create(:beis_organisation) }

  describe "#call" do
    let(:result) { described_class.new(organisation_id: organisation.id).call }

    it "sets the Organisation" do
      expect(result.organisation).to eq(organisation)
    end

    it "sets the initial wizard_status" do
      expect(result.wizard_status).to eq("identifier")
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
