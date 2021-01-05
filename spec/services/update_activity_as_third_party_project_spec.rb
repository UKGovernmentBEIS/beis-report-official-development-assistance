require "rails_helper"

RSpec.describe UpdateActivityAsThirdPartyProject do
  let(:beis) { create(:beis_organisation) }
  let(:activity) { create(:third_party_project_activity, :blank_form_state) }
  let(:parent) { create(:project_activity) }

  describe "#call" do
    let(:result) {
      described_class.new(activity: activity, parent_id: parent.id).call
    }

    context "when the activity organisation is a Government organisation" do
      it "uses the service owner as the reporting organisation" do
        expect(result.reporting_organisation).to eq(beis)
      end
    end

    context "when the activity organisation is a non-governmental organisation" do
      let(:ngo) { create(:delivery_partner_organisation, organisation_type: 21) }
      let(:activity) { create(:third_party_project_activity, :blank_form_state, organisation: ngo) }

      it "sets the reporting organisation to be the delivery partner" do
        expect(result.reporting_organisation).to eq(ngo)
      end
    end

    it "sets the parent Activity to the project" do
      expect(result.parent).to eq(parent)
    end

    it "sets the initial form_state" do
      expect(result.form_state).to eq("parent")
    end

    it "sets the Activity level to 'third_party_project'" do
      expect(result.level).to eq("third_party_project")
    end

    it "sets the accountable organisation details to the service owner" do
      expect(result.accountable_organisation_name).to eq beis.name
      expect(result.accountable_organisation_reference).to eq beis.iati_reference
      expect(result.accountable_organisation_type).to eq beis.organisation_type
    end

    it "sets the extending organisation to the owner of the activity" do
      expect(result.extending_organisation).to eq activity.organisation
    end

    context "when the parent activity cannot be found" do
      it "sets the parent to nil does not save the record" do
        result = described_class.new(activity: activity, parent_id: "an-id-that-does-not-exist").call
        expect(result.parent).to eq(nil)
        expect(result.errors.messages).to include(parent: [t("activerecord.errors.models.activity.attributes.parent.blank")])
      end
    end
  end
end
