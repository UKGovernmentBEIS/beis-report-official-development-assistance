require "rails_helper"

RSpec.describe CreateProjectActivity do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner_organisation) { create(:delivery_partner_organisation, organisation_type: 10) }
  let(:user) { create(:administrator, organisation: delivery_partner_organisation) }
  let(:programme) { create(:programme_activity, organisation: beis) }

  describe "#call" do
    let(:result) {
      described_class.new(user: user, organisation_id: user.organisation.id, programme_id: programme.id).call
    }

    it "sets the Organisation to that of users organisation" do
      expect(result.organisation).to eq delivery_partner_organisation
    end

    context "when the organisation is a Government organisation" do
      it "uses the service owner as the reporting organisation" do
        expect(result.reporting_organisation.iati_reference).to eq(beis.iati_reference)
      end
    end

    context "when the organisation is a non-governmental organisation" do
      let(:delivery_partner_organisation) { create(:delivery_partner_organisation, organisation_type: 21) }

      it "saves the reporting organisation" do
        expect(result.reporting_organisation.iati_reference).to eq(delivery_partner_organisation.iati_reference)
      end
    end

    it "sets the parent Activity to the programme" do
      expect(result.parent).to eq(programme)
    end

    it "sets fund and programme to be parent activities of the project" do
      fund = programme.parent
      programme = result.parent

      expect(result.parent_activities.first).to eq(fund)
      expect(result.parent_activities.last).to eq(programme)
    end

    it "sets the initial form_state" do
      expect(result.form_state).to eq("blank")
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
