RSpec.describe "Users can create a matched effort" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }

    let!(:project) { create(:project_activity, :with_report, organisation: user.organisation, parent: programme) }
    let!(:matched_effort_provider) { create(:matched_effort_provider) }
    let!(:matched_effort) { create(:matched_effort, activity: project) }

    before { authenticate!(user: user) }

    before do
      visit organisation_activity_path(project.organisation, project)

      click_on "Other funding"

      find("a[href='#{edit_activity_matched_effort_path(project, matched_effort)}']").click
    end

    scenario "they can edit a matched effort" do
      matched_effort.organisation = matched_effort_provider
      matched_effort.notes = "Here are some new notes"

      fill_in_matched_effort_form(matched_effort)

      expect(page).to have_content(t("action.matched_effort.update.success"))

      expect(matched_effort.reload.organisation).to eq(matched_effort_provider)
      expect(matched_effort.notes).to eq("Here are some new notes")
    end

    scenario "they see errors when a required field is missing" do
      select("", from: "matched_effort[organisation_id]")
      click_on t("default.button.submit")

      expect(page).to_not have_content(t("action.matched_effort.update.success"))

      expect(page).to have_content("Organisation can't be blank")
    end
  end
end
