require "rails_helper"

RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in via header link" do
    user = create(:administrator)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit root_path
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
    user = create(:administrator)
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

  scenario "any user lands on their organisation page" do
    user = create(:administrator)

    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit root_path
    expect(page).to have_content(I18n.t("page_title.welcome"))

    within ".app-header__user-links" do
      expect(page).to have_content(I18n.t("generic.link.sign_in"))
      click_on I18n.t("generic.link.sign_in")
    end

    expect(page).to have_content(user.organisation.name)
  end

  context "when the user doesn't have an organisation" do
    scenario "they see a 401 not authorised page" do
      user = build(:administrator, organisation: nil)
      user.save(validate: false)

      mock_successful_authentication(
        uid: user.identifier, name: user.name, email: user.email
      )

      visit root_path

      within ".app-header__user-links" do
        expect(page).to have_content(I18n.t("generic.link.sign_in"))
        click_on I18n.t("generic.link.sign_in")
      end

      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      expect(page).to have_content(I18n.t("page_content.errors.not_authorised.explanation"))
    end
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit dashboard_path

    expect(page).to have_content(I18n.t("page_title.welcome"))
  end

  context "when the Auth0 identifier does not match a user record" do
    scenario "informs the user their invitation has failed and the team has been notified" do
      user = create(:administrator, identifier: "a-local-identifier")
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

  context "when there was a problem and Auth0 redirects to /failure" do
    before(:each) do
      OmniAuth.config.mock_auth[:auth0] = :invalid_credentials
    end

    it "the user is shown what the error message so they can try to correct the problem themselves" do
      visit dashboard_path

      within ".app-header__user-links" do
        expect(page).to have_content(I18n.t("generic.link.sign_in"))
        click_on I18n.t("generic.link.sign_in")
      end

      expect(page).to have_content(I18n.t("page_content.errors.auth0.failed.explanation"))
      expect(page).to have_content("invalid_credentials")
      expect(page).to have_content(I18n.t("page_content.errors.auth0.failed.prompt"))
    end
  end
end
