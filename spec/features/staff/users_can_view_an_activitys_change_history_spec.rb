RSpec.feature "Users can view an activity's 'Change History' within a tab" do
  context "as a Delivery Partner user" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: user)
    end

    scenario "the activities page contains a _Change History_ tab" do
      programme = create(:programme_activity)
      activity = create(:project_activity, organisation: organisation, parent: programme)
      visit organisation_activity_path(organisation, activity)

      click_link "Change history"

      expect(page).to have_css("h2", text: t("page_title.activity.change_history"))
      expect(page).to have_content(t("page_content.tab_content.change_history.guidance"))
    end
  end
end
