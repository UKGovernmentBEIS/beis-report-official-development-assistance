require "rails_helper"

RSpec.describe UpdateActivityAsProgramme do
  let(:beis) { create(:beis_organisation) }
  let(:parent) { create(:fund_activity, :gcrf) }
  let(:activity) { create(:programme_activity, :blank_form_state) }

  describe "#call" do
    let(:result) { described_class.new(activity: activity, parent_id: parent.id).call }

    it "sets the parent Activity to the fund" do
      expect(result.parent).to eq(parent)
    end

    it "sets the source fund code to the project" do
      expect(result.source_fund_code).to eq(2)
    end

    it "sets the parent form_state" do
      expect(result.form_state).to eq("parent")
    end

    it "sets the Activity level to 'programme'" do
      expect(result.level).to eq("programme")
    end

    it "sets the accountable organisation details to the service owner" do
      expect(result.accountable_organisation_name).to eq beis.name
      expect(result.accountable_organisation_reference).to eq beis.iati_reference
      expect(result.accountable_organisation_type).to eq beis.organisation_type
    end

    it "does not the extending organisation to BEIS" do
      expect(result.extending_organisation).to eq beis
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
