RSpec.feature "Users can view all organisations" do
  before do
    authenticate!
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  scenario "organisation index page" do
    organisation = FactoryBot.create(:organisation)
    visit dashboard_path
    click_link I18n.t("page_content.dashboard.button.manage_organisations")

    expect(page).to have_content(I18n.t("page_title.organisation.index"))
    expect(page).to have_content organisation.name
  end
end
