require "rails_helper"

RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in" do
    user = create(:user)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit dashboard_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    click_on I18n.t("generic.link.start_now")

    expect(page).to have_content(I18n.t("page_title.dashboard"))
    expect(page).to have_content "Welcome back, #{user.name}"
    expect(page).to have_content(I18n.t("generic.link.sign_out"))
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit dashboard_path

    expect(page).to have_content(I18n.t("page_title.welcome"))
  end
end
