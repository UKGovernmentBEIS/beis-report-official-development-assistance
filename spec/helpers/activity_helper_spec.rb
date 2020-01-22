require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:organisation) }

  describe "#activity_back_path" do
    context "when the activity is a fund level" do
      it "returns the organistian path" do
        fund = create(:activity, level: :fund)
        expect(activity_back_path(fund)).to eq organisation_path(fund.organisation)
      end
    end

    context "when the activity is a programme level" do
      it "returns the fund path" do
        fund_activity = create(:activity, level: :fund)
        programme_activity = create(:activity, level: :programme)
        fund_activity.activities << programme_activity

        expect(activity_back_path(programme_activity)).to eq organisation_activity_path(fund_activity.organisation, fund_activity)
      end
    end
  end

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
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "flow")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "finance")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "tied_status")).to be(false)
      end
    end

    context "when the activity has passed the country step" do
      it "returns true for the previous field and only for the next field" do
        activity = build(:activity, :at_country_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "purpose")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "status")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "country")).to be(true)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "flow")).to be(true)
      end

      it "returns false for the next fields" do
        activity = build(:activity, :at_country_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "finance")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "tied_status")).to be(false)
      end
    end

    context "when the activity wizard hasn't been started" do
      it "shows no steps" do
        activity = build(:activity, :nil_wizard_status)
        all_steps = Staff::ActivityFormsController::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(false)
        end
      end
    end

    context "when the activity wizard has been completed" do
      it "shows all steps" do
        activity = build(:activity, wizard_status: "complete")
        all_steps = Staff::ActivityFormsController::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(true)
        end
      end
    end
  end
end
