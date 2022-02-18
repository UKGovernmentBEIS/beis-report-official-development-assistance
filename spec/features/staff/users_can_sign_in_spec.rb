require "rails_helper"

def log_in_via_form(user, remember_me: false)
  click_on t("header.link.sign_in")
  # type in username and password
  fill_in "Email", with: user.email
  fill_in "Password", with: user.password

  check "Remember me" if remember_me

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
    expect(page).to have_link(t("header.link.sign_out"))
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

  scenario "Logins can be remembered for 30 days" do
    user = create(:beis_user)

    visit root_path
    expect(page).to have_content(t("start_page.title"))

    log_in_via_form(user, remember_me: true)

    travel 29.days do
      visit reports_path
      expect(page).to have_content("Create a new report")
    end
    travel 31.days do
      visit reports_path
      expect(page).to have_content("Sign in")
    end
  end

  scenario "protected pages cannot be visited unless signed in" do
    visit root_path

    expect(page).to have_content(t("start_page.title"))
  end

  context "incorrect credentials are supplied" do
    it "displays the error message so they can try to correct the problem themselves" do
      user = double("User", email: "dont@exist.com", password: "anything")

      visit root_path

      log_in_via_form(user)

      expect(page).to have_content("Invalid Email or password")
    end
  end

  context "when the user has been deactivated" do
    scenario "the user cannot log in and sees an informative message" do
      pending "a viable Devise hook to use with User#active"
      user = create(:delivery_partner_user, active: false, identifier: "deactivated-user")

      visit root_path

      expect(page).to have_content(t("header.link.sign_in"))
      log_in_via_form(user)

      expect(page).to have_content(t("page_title.errors.not_authorised"))
      expect(page).to have_content(t("page_content.errors.not_authorised.explanation"))
    end

    scenario "a user who is logged in and then deactivated sees an error message" do
      pending "a viable Devise hook to use with User#active"
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
