RSpec.feature "Users can view an individual organisation" do
  let!(:organisation) { create(:organisation) }
  before do
    authenticate!
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  scenario "organisation show page" do
    organisation = FactoryBot.create(:organisation)
    visit dashboard_path
    click_link I18n.t("page_content.dashboard.button.manage_organisations")
    click_link organisation.name

    expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
  end

  scenario "can go back to the previous page" do
    visit organisation_path(organisation)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(organisations_path)
  end
end
