require "rails_helper"

RSpec.feature "Users can view the static pages" do
  scenario "the footer contains links to the privacy policy, terms of service, and accessiblity/cookie statements" do
    visit root_path

    within "footer" do
      expect(page).to have_link "Privacy policy", href: page_path("privacy_policy")
      expect(page).to have_link "Cookies", href: page_path("cookie_statement")
      expect(page).to have_link "Accessibility statement", href: page_path("accessibility_statement")
      expect(page).to have_link "Terms of service", href: page_path("terms_of_service")
      expect(page).to have_link "Service performance", href: "https://beisodahelp.zendesk.com/hc/en-gb/sections/1500001330861-Service-Performance"
      expect(page).to have_link "Support", href: "https://beisodahelp.zendesk.com/"
    end
  end
end
