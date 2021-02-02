require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#step_is_complete_or_next?" do
    context "when the activity has passed the identification step" do
      it "returns true for the purpose fields" do
        activity = build(:activity, :at_roda_identifier_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "purpose")).to be(true)
      end

      it "returns false for the next fields following the purpose field" do
        activity = build(:activity, :at_identifier_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "programme_status")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "region")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
      end
    end

    context "when the activity has passed the region step" do
      it "returns true for the previous field and only for the next field" do
        activity = build(:activity, :at_region_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "purpose")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "programme_status")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "region")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(true)
      end

      it "returns false for the next fields" do
        activity = build(:activity, :at_region_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
      end
    end

    context "when the activity form hasn't been started" do
      it "shows no steps" do
        activity = build(:activity, :nil_form_state)
        all_steps = Activity::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(false)
        end
      end
    end

    context "when the activity form has been completed" do
      it "shows all steps" do
        activity = build(:activity, form_state: "complete")
        all_steps = Activity::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(true)
        end
      end
    end

    context "when the activity is a fund" do
      context "and is at the indetifer step i.e. the parent step has been skipped" do
        it "returns true" do
          activity = build(:activity, :level_form_state, level: :fund, parent: nil)

          expect(helper.step_is_complete_or_next?(activity: activity, step: :identifier)).to be(true)
        end
      end
    end
  end

  describe "#link_to_activity_parent" do
    context "when there is no parent" do
      it "returns nil" do
        expect(helper.link_to_activity_parent(parent: nil, user: nil)).to be_nil
      end
    end

    context "when the parent is a fund" do
      context "and the user is delivery partner" do
        it "returns the parent title without a link" do
          parent_activity = create(:fund_activity)
          _activity = create(:programme_activity, parent: parent_activity)
          user = create(:delivery_partner_user)

          expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to eql parent_activity.title
        end
      end
    end

    context "when there is a parent" do
      it "returns a link to the parent" do
        parent_activity = create(:fund_activity)
        _activity = create(:programme_activity, parent: parent_activity)
        user = create(:beis_user)

        expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to include organisation_activity_path(parent_activity.organisation, parent_activity)
        expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to include parent_activity.title
      end
    end
  end

  describe "#custom_capitalisation" do
    context "when a string needs to be presented with the first letter of the first word upcased" do
      it "takes that string, upcases that letter and leaves the rest of the string as it is" do
        sample_string = "programme (level B)"
        expect(custom_capitalisation(sample_string)).to eql("Programme (level B)")
      end
    end
  end
end
