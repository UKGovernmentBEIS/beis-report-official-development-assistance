require "rails_helper"

RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in via header link" do
    user = create(:user)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit dashboard_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    within ".app-header__user-links" do
      expect(page).to have_content(I18n.t("generic.link.sign_in"))
      click_on I18n.t("generic.link.sign_in")
    end

    expect(page).to have_content(I18n.t("page_title.dashboard"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(I18n.t("generic.link.sign_out"))
  end

  scenario "successful sign in via button link" do
    user = create(:user)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit dashboard_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    within ".app-visitor-welcome" do
      expect(page).to have_content(I18n.t("generic.link.sign_in"))
      click_on I18n.t("generic.link.sign_in")
    end

    expect(page).to have_content(I18n.t("page_title.dashboard"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(I18n.t("generic.link.sign_out"))
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit dashboard_path

    expect(page).to have_content(I18n.t("page_title.welcome"))
  end

  context "when the Auth0 identifier does not match a user record" do
    scenario "informs the user their invitation has failed and the team has been notified" do
      user = create(:user, identifier: "a-local-identifier")
      mock_successful_authentication(
        uid: "an-unknown-identifier", name: user.name, email: user.email
      )

      visit dashboard_path

      within ".app-header__user-links" do
        expect(page).to have_content(I18n.t("generic.link.sign_in"))
        click_on I18n.t("generic.link.sign_in")
      end

      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      expect(page).to have_content(I18n.t("page_content.errors.not_authorised.explanation"))
    end
  end
end
