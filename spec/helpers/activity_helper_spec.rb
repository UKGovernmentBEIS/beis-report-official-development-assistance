require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#hierarchy_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the organisation_fund_path" do
        expect(helper.hierarchy_path_for(activity: fund_activity))
          .to eq(organisation_fund_path(organisation.id, fund))
      end
    end

    context "when the hierarchy_type is a programme" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:programme) { create(:programme, fund: fund) }
      let(:programme_activity) { create(:activity, hierarchy: programme) }

      it "returns the fund_programme_path" do
        expect(helper.hierarchy_path_for(activity: programme_activity))
          .to eq(fund_programme_path(fund, programme))
      end
    end
  end

  describe "#edit_hierarchy_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns edit_organisation_fund_path" do
        expect(helper.edit_hierarchy_path_for(activity: fund_activity))
          .to eq(edit_organisation_fund_path(organisation.id, fund))
      end
    end

    context "when the hierarchy_type is a programme" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:programme) { create(:programme, fund: fund) }
      let(:programme_activity) { create(:activity, hierarchy: programme) }

      it "returns edit_fund_programme_path" do
        expect(helper.edit_hierarchy_path_for(activity: programme_activity))
          .to eq(edit_fund_programme_path(fund, programme))
      end
    end
  end

  describe "#activity_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the fund_activity_path" do
        expect(helper.activity_path_for(activity: fund_activity))
          .to eq(fund_activity_path(fund, fund_activity))
      end
    end
  end

  describe "#edit_activity_path_for" do
    context "when the hierarchy_type is a fund" do
      let(:fund) { create(:fund, organisation: organisation) }
      let(:fund_activity) { create(:activity, hierarchy: fund) }

      it "returns the edit path for the first step by default" do
        expect(
          helper.edit_activity_path_for(activity: fund_activity)
        ).to eq(
          fund_activity_step_path(
            fund_id: fund,
            activity_id: fund_activity,
            id: :identifier
          )
        )
      end

      it "returns the edit path for the given step" do
        expect(
          helper.edit_activity_path_for(activity: fund_activity, step: :sector)
        ).to eq(
          fund_activity_step_path(
            fund_id: fund,
            activity_id: fund_activity,
            id: :sector
          )
        )
      end
    end
  end

  describe "#show_activity_field?" do
    context "when the activity has passed the identification step" do
      it "returns true for the purpose fields" do
        activity = build(:fund_activity, :at_identifier_step)
        expect(helper.show_activity_field?(activity: activity, step: "purpose")).to be(true)
      end

      it "returns false for the next fields following the purpose field" do
        activity = build(:fund_activity, :at_identifier_step)
        expect(helper.show_activity_field?(activity: activity, step: "sector")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "status")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "dates")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "country")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "flow")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "finance")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "aid_type")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "tied_status")).to be(false)
      end
    end

    context "when the activity has passed the country step" do
      it "returns true for the previous field and only for the next field" do
        activity = build(:fund_activity, :at_country_step)
        expect(helper.show_activity_field?(activity: activity, step: "purpose")).to be(true)
        expect(helper.show_activity_field?(activity: activity, step: "sector")).to be(true)
        expect(helper.show_activity_field?(activity: activity, step: "status")).to be(true)
        expect(helper.show_activity_field?(activity: activity, step: "dates")).to be(true)
        expect(helper.show_activity_field?(activity: activity, step: "country")).to be(true)
        expect(helper.show_activity_field?(activity: activity, step: "flow")).to be(true)
      end

      it "returns false for the next fields" do
        activity = build(:fund_activity, :at_country_step)
        expect(helper.show_activity_field?(activity: activity, step: "finance")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "aid_type")).to be(false)
        expect(helper.show_activity_field?(activity: activity, step: "tied_status")).to be(false)
      end
    end

    context "when the activity has a null .wizard_status field" do
      it "shows all steps" do
        activity = build(:fund_activity, :nil_wizard_status)
        all_steps = Staff::ActivityFormsController::FORM_STEPS

        all_steps.each do |step|
          expect(helper.show_activity_field?(activity: activity, step: step)).to be(true)
        end
      end
    end
  end
end
