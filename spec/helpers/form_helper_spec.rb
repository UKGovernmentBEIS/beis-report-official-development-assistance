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

  describe "#scoped_parent_activities" do
    let(:activities) { double(ActiveRecord::Relation) }

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
        allow_any_instance_of(FindFundActivities).to receive(:call) { activities }
        expect_any_instance_of(FindFundActivities).to receive(:call) { activities }
        expect(activities).to receive(:where).with(form_state: "complete")

        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end

    context "when the activity is a project" do
      it "tells FindProgrammeActivities to return the programme activities" do
        activity = build(:project_activity)
        allow_any_instance_of(FindProgrammeActivities).to receive(:call) { activities }
        expect_any_instance_of(FindProgrammeActivities).to receive(:call) { activities }
        expect(activities).to receive(:where).with(form_state: "complete")

        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end

    context "when the activity is a third-party project" do
      it "tells FindProjectActivities to return the project activities" do
        activity = build(:third_party_project_activity)
        allow_any_instance_of(FindProjectActivities).to receive(:call) { activities }
        expect_any_instance_of(FindProjectActivities).to receive(:call) { activities }
        expect(activities).to receive(:where).with(form_state: "complete")

        helper.scoped_parent_activities(activity: activity, user: double(User))
      end
    end
  end

  describe "#create_activity_level_options" do
    context "when the user is a BEIS user" do
      it "tells Pundit to return only the levels of activity a user can create or update" do
        user = create(:beis_user)
        result = helper.create_activity_level_options(user: user)
        expect(result).to eq([
          OpenStruct.new(
            level: "programme",
            name: "Programme (level B)",
            description: t("form.hint.activity.level_step.programme"),
          ),
        ])
      end
    end

    context "when the user is a DP user" do
      it "tells Pundit to return only the levels of activity a user can create or update" do
        user = create(:delivery_partner_user)
        result = helper.create_activity_level_options(user: user)

        expect(result).to eq([
          OpenStruct.new(
            level: "project",
            name: "Project (level C)",
            description: t("form.hint.activity.level_step.project")
          ),
        ])
      end
    end
  end
end
