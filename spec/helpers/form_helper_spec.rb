require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_organisations" do
    it "asks for a sorted list of organisations" do
      expect(Organisation).to receive(:sorted_by_name)
      helper.list_of_organisations
    end
  end

  describe "#list_of_delivery_partners" do
    it "asks for a list of organisations that are not `service_owner`" do
      delivery_partner = build_stubbed(:organisation, service_owner: false)
      allow(Organisation).to receive(:delivery_partners).and_return([delivery_partner])

      expect(Organisation).to receive(:delivery_partners)
      helper.list_of_delivery_partners
    end
  end

  describe "#list_of_planned_disbursement_budget_types" do
    it "builds a list of budget types for a planned disbursement" do
      budget_types = helper.list_of_planned_disbursement_budget_types

      expect(budget_types[0].name).to eq I18n.t("form.label.planned_disbursement.planned_disbursement_type_options.original.name")
      expect(budget_types[0].description).to eq I18n.t("form.label.planned_disbursement.planned_disbursement_type_options.original.description")
    end
  end

  describe "#scoped_parent_activities" do
    context "when the activity is a fund" do
      it "returns an empty result" do
        activity = build(:fund_activity)
        result = helper.scoped_parent_activities(activity: activity, user: double(User))
        expect(result).to eq(Activity.none)
      end
    end

    context "when the activity is a programme" do
      it "tells FindFundActivities to return the fund activities" do
        activity = build(:programme_activity)
        allow_any_instance_of(FindFundActivities).to receive(:call)
        expect_any_instance_of(FindFundActivities).to receive(:call)
        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end

    context "when the activity is a project" do
      it "tells FindProgrammeActivities to return the programme activities" do
        activity = build(:project_activity)
        allow_any_instance_of(FindProgrammeActivities).to receive(:call)
        expect_any_instance_of(FindProgrammeActivities).to receive(:call)
        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end

    context "when the activity is a third-party project" do
      it "tells FindProjectActivities to return the project activities" do
        activity = build(:third_party_project_activity)
        allow_any_instance_of(FindProjectActivities).to receive(:call)
        expect_any_instance_of(FindProjectActivities).to receive(:call)
        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end
  end
end
