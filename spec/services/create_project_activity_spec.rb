require "rails_helper"

RSpec.describe CreateProjectActivity do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner_organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:administrator, organisation: delivery_partner_organisation) }
  let(:programme) { create(:programme_activity, organisation: beis) }

  describe "#call" do
    let(:result) {
      described_class.new(user: user, organisation_id: user.organisation.id, programme_id: programme.id).call
    }

    it "sets the Organisation to that of users organisation" do
      expect(result.organisation).to eq delivery_partner_organisation
    end

    it "saves the reporting organisation reference" do
      expect(result.reporting_organisation_reference).to eq(delivery_partner_organisation.iati_reference)
    end

    it "sets the parent Activity to the fund" do
      expect(result.activity).to eq(programme)
    end

    it "sets the initial wizard_status" do
      expect(result.wizard_status).to eq("blank")
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
