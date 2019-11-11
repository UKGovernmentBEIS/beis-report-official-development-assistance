require "rails_helper"

RSpec.feature "Users can sign out of service" do
  scenario "successful sign out" do
    mock_successful_authentication
    stub_authenticated_session

    visit root_path
    click_on I18n.t("generic.link.start_now")
    expect(page).to have_content(I18n.t("page_title.dashboard"))

    click_on "Sign out"

    expect(page).to have_content(I18n.t("page_title.welcome"))
    expect(page).not_to have_content(I18n.t("generic.link.sign_out"))
  end
end
