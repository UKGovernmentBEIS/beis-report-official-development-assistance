require "rails_helper"

RSpec.feature "Users can view the privacy policy" do
  scenario "the footer contains a link to the privacy policy" do
    visit root_path

    within("footer") do
      expect(page).to have_link t("footer.link.privacy_policy")
    end
  end

  scenario "the linked privacy policy page can be viewed" do
    visit root_path
    click_on t("footer.link.privacy_policy")

    expect(page).to have_content t("page_title.privacy_policy")
  end
end
