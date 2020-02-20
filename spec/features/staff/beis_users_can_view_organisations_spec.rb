RSpec.feature "BEIS users can view other organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    scenario "all organisations can be viewed" do
      another_organisation = create(:organisation)
      authenticate!(user: user)

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisation.index"))
      expect(page).to have_content(user.organisation.name)
      expect(page).to have_content(another_organisation.name)
    end

    scenario "can go back to the previous page" do
      authenticate!(user: user)

      visit organisations_path

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(user.organisation))
    end
  end
end
