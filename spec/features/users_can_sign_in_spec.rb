require "rails_helper"

RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in" do
    mock_successful_authentication(name: "Alex Smith")

    visit dashboard_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    stub_authenticated_session(name: "Alex Smith", email: "alex@example.com")
    visit root_path

    click_on I18n.t("generic.link.start_now")

    expect(page).to have_content(I18n.t("page_title.dashboard"))
    expect(page).to have_content "Welcome back, Alex Smith"
    expect(page).to have_content(I18n.t("generic.link.sign_out"))
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit dashboard_path

    expect(page).to have_content(I18n.t("page_title.welcome"))
  end
end
