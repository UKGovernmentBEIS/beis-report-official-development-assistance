require "rails_helper"

RSpec.feature "Fund managers can view other users" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit users_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:administrator)) }

    scenario "a user can be viewed" do
      another_user = create(:delivery_partner)

      # Navigate from the landing page
      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_users"))

      # Navigate to the users page
      expect(page).to have_content(I18n.t("page_title.users.index"))
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)

      # Navigate to the individual user page
      within(".users") do
        click_on(I18n.t("generic.link.show"))
      end

      expect(page).to have_content(I18n.t("page_title.users.show"))
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)
    end

    scenario "can go back to the previous page" do
      another_user = create(:delivery_partner)

      visit user_path(another_user)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(users_path)
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner)) }

    scenario "cannot view the user" do
      visit dashboard_path
      expect(page).not_to have_content(
        I18n.t("page_content.dashboard.button.manage_users")
      )
    end

    scenario "cannot view all users" do
      visit users_path
      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
    end
  end
end
