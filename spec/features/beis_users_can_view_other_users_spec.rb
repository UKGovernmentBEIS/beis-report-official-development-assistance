require "rails_helper"

RSpec.feature "BEIS users can can view other users" do
  context "when the user is not logged in" do
    before do
      logout
    end

    it "redirects the user to the root path" do
      visit users_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:beis_user) }

    before do
      authenticate!(user: user)
    end

    after { logout }

    scenario "an active user can be viewed" do
      another_user = create(:administrator)

      # Navigate from the landing page
      visit organisation_path(user.organisation)
      click_on(t("page_title.users.index"))

      # Navigate to the users page
      expect(page).to have_content(t("page_title.users.index"))
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)
      expect(page).to have_content(another_user.organisation.name)

      # Navigate to the individual user page
      within(".users") do
        find("tr", text: another_user.name).click_link(t("default.link.show"))
      end

      expect(page).to have_content(t("page_title.users.show"))
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)
      expect(page).to have_content("Mobile number confirmed for authentication? Yes")
    end

    scenario "an inactive user can be viewed" do
      another_user = create(:inactive_user, deactivated_at: DateTime.now - 1.hour)

      # Navigate from the landing page
      visit organisation_path(user.organisation)
      click_on(t("page_title.users.index"))
      # Navigate to inactive users tab
      click_on(t("tabs.users.inactive"))

      expect(page).to have_content("1 hour")

      # Navigate to the individual user page
      within(".users") do
        find("tr", text: another_user.name).click_link(t("default.link.show"))
      end

      expect(page).to have_content("Active? No")
      expect(page).to have_content("1 hour")
    end
  end
end
