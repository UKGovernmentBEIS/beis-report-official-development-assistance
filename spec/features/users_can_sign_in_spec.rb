RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in" do
    mock_successful_authentication

    visit dashboard_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    click_on "Start now"

    expect(page).to have_content(I18n.t("page_title.dashboard"))
    expect(page).to have_content(I18n.t("generic.link.sign_out"))
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit dashboard_path

    expect(page).to have_content(I18n.t("page_title.welcome"))
  end
end
