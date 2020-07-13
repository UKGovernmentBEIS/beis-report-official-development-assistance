require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#step_is_complete_or_next?" do
    context "when the activity has passed the identification step" do
      it "returns true for the purpose fields" do
        activity = build(:activity, :at_identifier_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "purpose")).to be(true)
      end

      it "returns false for the next fields following the purpose field" do
        activity = build(:activity, :at_identifier_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "status")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "region")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "flow")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
      end
    end

    context "when the activity has passed the region step" do
      it "returns true for the previous field and only for the next field" do
        activity = build(:activity, :at_region_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "purpose")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "status")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "region")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "flow")).to be(false)
      end

      it "returns false for the next fields" do
        activity = build(:activity, :at_region_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
      end
    end

    context "when the activity form hasn't been started" do
      it "shows no steps" do
        activity = build(:activity, :nil_form_state)
        all_steps = Staff::ActivityFormsController::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(false)
        end
      end
    end

    context "when the activity form has been completed" do
      it "shows all steps" do
        activity = build(:activity, form_state: "complete")
        all_steps = Staff::ActivityFormsController::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(true)
        end
      end
    end
  end
end
