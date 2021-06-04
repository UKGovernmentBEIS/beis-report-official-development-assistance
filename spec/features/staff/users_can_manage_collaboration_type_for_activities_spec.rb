RSpec.feature "Users can add a collaboration type for an activity" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }
  let(:activity) { create(:programme_activity, :at_collaboration_type_step, organisation: user.organisation) }

  context "when the user creates a new activity, on the collaboration_type form step" do
    scenario "the activity has a pre-selected radio button for collaboration_type with value '1 -Bilateral'" do
      visit activity_step_path(activity, :collaboration_type)

      expect(find_field("activity-collaboration-type-1-field")).to be_checked
      expect(find_field("activity-collaboration-type-2-field")).not_to be_checked
    end

    context "and they save this step without changing the selected radio button" do
      it "saves collaboration_type as value '1' (Bilateral)" do
        visit activity_step_path(activity, :collaboration_type)
        click_button t("form.button.activity.submit")

        expect(activity.reload.collaboration_type).to eq("1")
      end
    end
  end

  context "when the user wants to edit the collaboration_type on an existing activity" do
    it "shows the correct radio button selected" do
      programme = create(:programme_activity, organisation: user.organisation, collaboration_type: "2")
      visit organisation_activity_details_path(programme.organisation, programme)
      within(".collaboration_type") do
        click_on(t("default.link.edit"))
      end

      expect(find_field("activity-collaboration-type-2-field")).to be_checked

      choose "Bilateral, core contributions to NGOs and other private bodies / PPPs"
      click_button t("form.button.activity.submit")

      expect(programme.reload.collaboration_type).to eq("3")
    end
  end
end
