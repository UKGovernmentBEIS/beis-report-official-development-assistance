require "rails_helper"

RSpec.feature "Users can sign in with Auth0" do
  scenario "successful sign in via header link" do
    user = create(:administrator)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    expect(page).to have_content(t("header.link.sign_in"))
    click_on t("header.link.sign_in")

    expect(page).to have_content(user.organisation.name)
    expect(page).to have_content(t("header.link.sign_out"))
  end

  scenario "successful sign in via button link" do
    user = create(:administrator)
    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    expect(page).to have_content(t("header.link.sign_in"))
    click_on t("header.link.sign_in")

    expect(page).to have_content(user.organisation.name)
    expect(page).to have_content(t("header.link.sign_out"))
  end

  scenario "a user is redirected to a link they originally requested" do
    user = create(:administrator)

    visit reports_path

    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    click_on t("header.link.sign_in")

    expect(current_path).to eq(reports_path)
  end

  scenario "any user lands on their organisation page" do
    user = create(:administrator)

    mock_successful_authentication(
      uid: user.identifier, name: user.name, email: user.email
    )

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    expect(page).to have_content(t("header.link.sign_in"))
    click_on t("header.link.sign_in")

    expect(page).to have_content(user.organisation.name)
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit root_path

    expect(page).to have_content(t("start_page.title"))
  end

  context "when the Auth0 identifier does not match a user record" do
    scenario "informs the user their invitation has failed and the team has been notified" do
      user = create(:administrator, identifier: "a-local-identifier")
      mock_successful_authentication(
        uid: "an-unknown-identifier", name: user.name, email: user.email
      )

      visit root_path

      expect(page).to have_content(t("header.link.sign_in"))
      click_on t("header.link.sign_in")

      expect(page).to have_content(t("page_title.errors.not_authorised"))
      expect(page).to have_content(t("page_content.errors.not_authorised.explanation"))
    end
  end

  context "when there was a known error message and the user is redirected to /auth/failure" do
    before(:each) do
      OmniAuth.config.mock_auth[:auth0] = :invalid_credentials
    end

    it "displays the error message so they can try to correct the problem themselves" do
      visit root_path

      expect(page).to have_content(t("header.link.sign_in"))
      click_on t("header.link.sign_in")

      expect(page).to have_content(t("page_content.errors.auth0.failed.explanation"))
      expect(page).to have_content(t("page_content.errors.auth0.error_messages.invalid_credentials"))
      expect(page).to have_content(t("page_content.errors.auth0.failed.prompt"))
    end
  end

  context "when there was an unknown error message and the user is redirected to /auth/failure" do
    before(:each) do
      OmniAuth.config.mock_auth[:auth0] = :unknown_failure
    end

    it "displays a generic error message and logs to Rollbar" do
      allow(Rollbar).to receive(:log)

      visit root_path

      click_button t("header.link.sign_in")

      expect(page).not_to have_content("unknown_failure")
      expect(page).to have_content(t("page_content.errors.auth0.error_messages.generic"))
      expect(Rollbar).to have_received(:log).with(:info, "Unknown response from Auth0", "unknown_failure")
    end
  end

  context "when the user has been deactivated" do
    scenario "the user cannot log in and sees an informative message" do
      user = create(:delivery_partner_user, active: false, identifier: "deactivated-user")
      mock_successful_authentication(
        uid: "deactivated-user", name: user.name, email: user.email
      )

      visit root_path

      expect(page).to have_content(t("header.link.sign_in"))
      click_on t("header.link.sign_in")

      expect(page).to have_content(t("page_title.errors.not_authorised"))
      expect(page).to have_content(t("page_content.errors.not_authorised.explanation"))
    end
  end
end
