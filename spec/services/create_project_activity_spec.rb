require "rails_helper"

RSpec.describe CreateProjectActivity do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner_organisation) { create(:delivery_partner_organisation) }
  let(:delivery_partner_user) { create(:delivery_partner, organisation: delivery_partner_organisation) }
  let(:programme) { create(:programme_activity, organisation: beis) }

  describe "#call" do
    let(:result) {
      described_class.new(user: delivery_partner_user, organisation_id: beis.id, programme_id: programme.id).call
    }

    it "sets the Organisation to that of the parent programme i.e. BEIS" do
      expect(result.organisation).to eq beis
    end

    it "sets the parent Activity to the fund" do
      expect(result.activity).to eq(programme)
    end

    it "sets the initial wizard_status" do
      expect(result.wizard_status).to eq("identifier")
    end

    it "sets the Activity level to 'project'" do
      expect(result.level).to eq("project")
    end

    it "sets the funding organisation details" do
      expect(result.funding_organisation_name).to eq beis.name
      expect(result.funding_organisation_reference).to eq beis.iati_reference
      expect(result.funding_organisation_type).to eq beis.organisation_type
    end

    it "sets the accountable organisation details" do
      expect(result.accountable_organisation_name).to eq beis.name
      expect(result.accountable_organisation_reference).to eq beis.iati_reference
      expect(result.accountable_organisation_type).to eq beis.organisation_type
    end

    it "sets the extending organisation to that of signed in delivery partner" do
      expect(result.extending_organisation).to eq delivery_partner_organisation
    end
  end
end
