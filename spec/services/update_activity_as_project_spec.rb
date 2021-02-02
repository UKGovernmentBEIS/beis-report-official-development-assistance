require "rails_helper"

RSpec.describe UpdateActivityAsProject do
  let(:beis) { create(:beis_organisation) }
  let(:parent) { create(:programme_activity, :newton_funded) }
  let(:activity) { create(:project_activity) }

  describe "#call" do
    let(:result) {
      described_class.new(activity: activity, parent_id: parent.id).call
    }

    context "when the organisation is a Government organisation" do
      it "sets the reporting organisation to be the service owner" do
        expect(result.reporting_organisation).to eq(beis)
      end
    end

    context "when the organisation is a non-governmental organisation" do
      let(:activity) { create(:project_activity, organisation: ngo) }
      let(:ngo) { create(:delivery_partner_organisation, organisation_type: 21) }

      it "sets the reporting organisation to be the delivery partner" do
        expect(result.reporting_organisation).to eq(ngo)
      end
    end

    it "sets the parent Activity to the programme" do
      expect(result.parent).to eq(parent)
    end

    it "sets the source fund code to the programme" do
      expect(result.source_fund_code).to eq(1)
    end

    it "sets the initial form_state" do
      expect(result.form_state).to eq("parent")
    end

    it "sets the Activity level to 'project'" do
      expect(result.level).to eq("project")
    end

    it "sets the accountable organisation details to the service owner" do
      expect(result.accountable_organisation_name).to eq beis.name
      expect(result.accountable_organisation_reference).to eq beis.iati_reference
      expect(result.accountable_organisation_type).to eq beis.organisation_type
    end

    it "sets the extending organisation to owner of the activity" do
      expect(result.extending_organisation).to eq activity.organisation
    end

    context "when the parent activity cannot be found" do
      it "sets the parent to nil and does not save the record" do
        result = described_class.new(activity: activity, parent_id: "an-id-that-does-not-exist").call
        expect(result.parent).to eq(nil)
        expect(result.errors.messages).to include(parent: [t("activerecord.errors.models.activity.attributes.parent.blank")])
      end
    end
  end
end
