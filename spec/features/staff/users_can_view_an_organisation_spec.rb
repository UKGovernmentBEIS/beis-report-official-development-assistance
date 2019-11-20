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

    visit organisation_path(organisation)

    expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
  end
end
