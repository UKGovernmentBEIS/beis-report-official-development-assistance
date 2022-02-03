require "rails_helper"

def log_in_via_form(user)
  click_on t("header.link.sign_in")
  # type in username and password
  fill_in "Email", with: user.email
  fill_in "Password", with: user.password
  click_on "Log in"
end

RSpec.feature "Users can sign in" do
  scenario "successful sign in via header link" do
    # Given a user exists
    user = create(:administrator)

    # When I log in with that user's credentials
    visit root_path
    expect(page).to have_content(t("start_page.title"))

    expect(page).to have_content(t("header.link.sign_in"))

    log_in_via_form(user)

    # Then I should be logged in.
    expect(page).to have_content(t("header.link.sign_out"))
    expect(page).to have_content("Signed in successfully.")

    # And at the home page
    expect(page).to have_content("You can search by RODA, Delivery Partner, or BEIS identifier, or by the activity's title")
  end

  scenario "a user is redirected to a link they originally requested" do
    user = create(:administrator)

    visit reports_path

    log_in_via_form(user)

    expect(current_path).to eq(reports_path)
  end

  scenario "a BEIS user lands on their home page" do
    user = create(:beis_user)

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    log_in_via_form(user)

    expect(page.current_path).to eql home_path
  end

  scenario "a delivery partner user lands on their home page" do
    user = create(:delivery_partner_user)

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    log_in_via_form(user)
    expect(page.current_path).to eql home_path
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

    scenario "a user who is logged in and then deactivated sees an error message" do
      user = create(:delivery_partner_user)

      mock_successful_authentication(
        uid: user.identifier, name: user.name, email: user.email
      )

      visit root_path
      click_on t("header.link.sign_in")

      expect(page.current_path).to eql home_path

      user.active = false
      user.save

      visit home_path

      expect(page).to have_content(t("page_title.errors.not_authorised"))
      expect(page).to have_content(t("page_content.errors.not_authorised.explanation"))
    end
  end
end
