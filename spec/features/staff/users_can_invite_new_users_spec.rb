require "rails_helper"

RSpec.feature "users can invite new users to the service" do
  before(:each) do
    log_in
    stub_auth0_token_request
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
    visit dashboard_path
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
      visit new_user_path

      expect(page).to have_content(I18n.t("page_title.users.new"))
      fill_in "user[name]", with: "" # deliberately omit a value
      fill_in "user[email]", with: "" # deliberately omit a value

      click_button I18n.t("form.user.submit")

      expect(page).to have_content("Name\ncan't be blank")
      expect(page).to have_content("Email\ncan't be blank")
    end
  end

  context "when there was an error creating the user in auth0" do
    it "does not create the user and displays an error message" do
      stub_auth0_token_request
      new_email = "email@example.com"
      stub_auth0_create_user_request_failure(email: new_email)

      visit new_user_path

      expect(page).to have_content(I18n.t("page_title.users.new"))
      fill_in "user[name]", with: "foo"
      fill_in "user[email]", with: new_email

      click_button I18n.t("form.user.submit")

      expect(page).to have_content(I18n.t("form.user.create.failed"))
      expect(User.find_by(email: new_email)).to eq(nil)
    end
  end

  scenario "a new user can be associated to multiple organisations" do
    first_organisation = create(:organisation)
    second_organisation = create(:organisation)

    new_user_name = "Foo Bar"
    new_user_email = "email@example.com"
    auth0_identifier = "auth0|00991122"

    stub_auth0_create_user_request(
      email: new_user_email,
      auth0_identifier: auth0_identifier
    )

    # Navigate from the landing page
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))

    # Create a new user
    click_on(I18n.t("page_content.users.button.create"))

    # Fill out the form
    expect(page).to have_content(I18n.t("page_title.users.new"))
    fill_in "user[name]", with: new_user_name
    fill_in "user[email]", with: new_user_email
    check first_organisation.name
    check second_organisation.name

    # Submit the form
    click_button I18n.t("form.user.submit")

    within(".organisations") do
      expect(page).to have_content(first_organisation.name)
      expect(page).to have_content(second_organisation.name)
    end
  end

  scenario "can go back to the previous page" do
    visit new_user_path

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(users_path)
  end
end
