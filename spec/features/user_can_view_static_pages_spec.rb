require "rails_helper"

RSpec.feature "Users can view the static pages" do
  scenario "the footer contains links to the privacy policy, terms of service, and accessiblity/cookie statements" do
    visit root_path

    within "footer" do
      expect(page).to have_link t("footer.link.privacy_policy"), href: page_path("privacy_policy")
      expect(page).to have_link t("footer.link.cookie_statement"), href: page_path("cookie_statement")
      expect(page).to have_link t("footer.link.accessibility_statement"), href: page_path("accessibility_statement")
      expect(page).to have_link t("footer.link.terms_of_service"), href: page_path("terms_of_service")
      expect(page).to have_link t("footer.link.support_site"), href: "https://beisodahelp.zendesk.com/"
    end
  end
end
