require "rails_helper"

RSpec.feature "users can invite new users to the service" do
  before(:each) do
    stub_authenticated_session
  end

  scenario "a new user can be created" do
    new_user_name = "Foo Bar"
    new_user_email = "email@example.com"
    auth0_identifier = "auth0|00991122"

    stub_auth0_create_user_request(
      email: new_user_email,
      auth0_identifier: auth0_identifier
    )

    # Navigate from the landing page
    visit root_path
    click_on(I18n.t("generic.link.start_now"))
    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))

    # Create a new user
    click_on(I18n.t("page_content.users.button.create"))

    # Fill out the form
    expect(page).to have_content(I18n.t("page_title.users.new"))
    fill_in "user[name]", with: new_user_name
    fill_in "user[email]", with: new_user_email

    # Submit the form
    click_button I18n.t("form.user.submit")

    # Verify the new user exists
    expect(page).to have_content(I18n.t("page_title.users.show"))
    expect(page).to have_content(new_user_name)
    expect(page).to have_content(new_user_email)
    expect(page).to have_content(auth0_identifier)
  end

  context "when the name and email are not provided" do
    it "shows the user validation errors instead" do
    end
  end

  context "when there was an error creating the user in auth0" do
  end
end
