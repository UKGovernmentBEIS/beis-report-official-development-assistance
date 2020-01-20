RSpec.feature "Users can view organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund manager" do
    scenario "organisation index page" do
      organisation = create(:organisation)
      authenticate!(user: create(:fund_manager))

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisation.index"))
      expect(page).to have_content organisation.name
    end

    scenario "can go back to the previous page" do
      authenticate!(user: create(:fund_manager))

      visit organisations_path

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(dashboard_path)
    end
  end

  context "when the user is a delivery partner" do
    scenario "organisation index page" do
      organisation = create(:organisation)
      authenticate!(user: create(:delivery_partner, organisation: organisation))

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisation.index"))
      expect(page).to have_content organisation.name
    end

    scenario "can go back to the previous page" do
      organisation = create(:organisation)
      authenticate!(user: create(:delivery_partner, organisation: organisation))

      visit organisations_path

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(dashboard_path)
    end

    context "when the user is a delivery partner" do
      scenario "cannot see the organisation" do
        organisation_they_belong_to = create(:organisation)
        another_organisation = create(:organisation)
        authenticate!(user: create(:delivery_partner, organisation: organisation_they_belong_to))

        visit organisations_path

        expect(page).to have_content(I18n.t("page_title.organisation.index"))
        expect(page).to have_content organisation_they_belong_to.name
        expect(page).not_to have_content another_organisation.name
      end
    end
  end
end
