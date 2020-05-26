require "rails_helper"

RSpec.feature "Users can view the privacy policy" do
  scenario "the footer contains a link to the privacy policy" do
    visit root_path

    within("footer") do
      expect(page).to have_link I18n.t("page_content.generic.link.privacy_policy")
    end
  end

  scenario "the linked privacy policy page can be viewed" do
    visit root_path
    click_on I18n.t("page_content.generic.link.privacy_policy")

    expect(page).to have_content I18n.t("page_title.privacy_policy")
  end
end
