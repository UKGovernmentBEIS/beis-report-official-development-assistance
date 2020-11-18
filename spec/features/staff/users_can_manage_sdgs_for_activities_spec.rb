RSpec.feature "Users can add Sustainable Development Goals for an activity" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }
  let(:activity) { create(:programme_activity, :at_sustainable_development_goals_step, organisation: user.organisation) }

  context "when the user creates a new activity, on the sustainable_development_goals form step" do
    scenario "they can choose up to three SDGs" do
      visit activity_step_path(activity, :sustainable_development_goals)

      choose "activity[sdgs_apply]", option: "true"

      select "Quality Education", from: "activity[sdg_1]"
      select "Gender Equality", from: "activity[sdg_2]"
      select "Climate Action", from: "activity[sdg_3]"

      click_button t("form.button.activity.submit")

      activity.reload

      expect(activity.sdg_1).to eql 4
      expect(activity.sdg_2).to eql 5
      expect(activity.sdg_3).to eql 13
    end

    scenario "the first Sustainable Development Goal is required" do
      visit activity_step_path(activity, :sustainable_development_goals)

      choose "activity[sdgs_apply]", option: "true"
      select "N/A", from: "activity[sdg_1]"

      click_button t("form.button.activity.submit")

      expect(page).to have_content t("activerecord.errors.models.activity.attributes.sdg_1.blank")
    end
  end
end
