RSpec.feature "Users can view all organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is an administrator" do
    scenario "they can see all organisations" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      authenticate!(user: user)

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisation.index"))
      expect(page).to have_content organisation.name
    end
  end

  context "when the user is a delivery_partner" do
    scenario "they can only see organisations they are associated with" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      user = create(:delivery_partner, organisations: [organisation])
      authenticate!(user: user)

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisation.index"))
      expect(page).to have_content organisation.name
      expect(page).not_to have_content other_organisation.name
    end
  end

  scenario "can go back to the previous page" do
    authenticate!(user: build_stubbed(:user))

    visit organisations_path

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(dashboard_path)
  end
end
