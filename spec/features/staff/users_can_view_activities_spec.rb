RSpec.feature "Users can view activities" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit activities_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when there are activities belonging to a fund in the user's organisation" do
    scenario "the user will see them on the activities index page" do
      fund = create(:fund, organisation: organisation)
      activity = create(:activity, fund: fund)

      visit activities_path

      expect(page).to have_content(I18n.t("page_title.activity.index"))
      expect(page).to have_content activity.identifier
    end
  end

  context "when there are activities belonging to funds in another organisation" do
    scenario "the user will not see them on the activities index page" do
      skip "Not implemented yet"
      organisation_2 = create(:organisation)
      fund_2 = create(:fund, organisation: organisation_2)
      activity = create(:activity, fund: fund_2)

      visit activities_path

      expect(page).to have_content(I18n.t("page_title.activity.index"))
      expect(page).not_to have_content activity.identifier
    end
  end

  scenario "can go back to the previous page" do
    visit activities_path

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(dashboard_path)
  end
end
