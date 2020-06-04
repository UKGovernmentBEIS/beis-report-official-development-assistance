require "rails_helper"

RSpec.feature "Users can view the static pages" do
  context "when not signed in" do
    scenario "the footer contains a link to the privacy policy" do
      visit root_path

      within("footer") do
        expect(page).to have_link I18n.t("footer.link.privacy_policy")
      end
    end

    scenario "the linked privacy policy page can be viewed" do
      visit root_path
      click_on I18n.t("footer.link.privacy_policy")

      expect(page).to have_content I18n.t("page_title.privacy_policy")
    end

    scenario "the footer contains a link to the cookie statment" do
      visit root_path

      within("footer") do
        expect(page).to have_link I18n.t("footer.link.cookie_statement")
      end
    end

    scenario "the linked cookie statement page can be viewed" do
      visit root_path
      click_on I18n.t("footer.link.cookie_statement")

      expect(page).to have_content I18n.t("page_title.cookie_statement.title")
    end
  end

  context "when signed in" do
    scenario "static pages can be viewed" do
      user = create(:delivery_partner_user)
      authenticate!(user: user)
      visit privacy_policy_path

      expect(page).to have_content I18n.t("page_title.privacy_policy")

      visit cookie_statement_path

      expect(page).to have_content I18n.t("page_title.cookie_statement.title")
    end
  end
end
