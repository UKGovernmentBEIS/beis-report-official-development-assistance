RSpec.feature "Users can view funds" do
  before do
    authenticate!(user: user)
  end

  let(:user_organisation) { create(:organisation) }
  let(:other_organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [user_organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit funds_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when there are funds belonging to the user's organisation" do
    scenario "the user will see them on the organisation show page" do
      fund = create(:fund, organisation: user_organisation)
      visit organisations_path
      click_link user_organisation.name

      expect(page).to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).to have_content fund.name
    end
  end

  context "when there are funds belonging to another organisation" do
    scenario "the user will not see them on the show page for their organisation" do
      fund = create(:fund, organisation: other_organisation)
      visit organisations_path
      click_link user_organisation.name

      expect(page).to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).not_to have_content fund.name
    end
  end

  scenario "can go back to the previous page" do
    visit funds_path

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(dashboard_path)
  end
end
