require "rails_helper"

RSpec.feature "BEIS users can editing other users" do
  let!(:user) { create(:administrator, organisation: create(:organisation)) }

  before do
    stub_auth0_token_request
  end

  scenario "the details of the user can be updated" do
    user = create(:beis_user)
    authenticate!(user: user)

    target_user = create(:administrator, name: "Old Name", email: "old@example.com")

    updated_name = "New Name"
    updated_email = "new@example.com"

    stub_auth0_update_user_request(
      auth0_identifier: target_user.identifier,
      email: updated_email,
      name: updated_name
    )

    # Navigate from the landing page
    visit organisation_path(user.organisation)

    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))

    # Find the target user and click on edit button

    find("tr", text: target_user.name).click_link("Edit")

    # Fill out the form
    fill_in "user[name]", with: updated_name
    fill_in "user[email]", with: updated_email

    # Submit the form
    click_button I18n.t("form.user.submit")

    # Verify the user was updated
    expect(page).to have_content(updated_name)
    expect(page).to have_content(updated_email)
  end

  scenario "the role can be changed" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Manage users"

    expect(page).to have_content(user.name)

    find("tr", text: user.name).click_link("Edit")

    choose "Administrator"
    click_on "Submit"

    expect(user.reload.role).to eql("administrator")
  end

  scenario "an active user can be deactivated" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Manage users"
    find("tr", text: user.name).click_link("Edit")

    choose I18n.t("form.user.active.inactive")
    click_on I18n.t("generic.button.submit")

    expect(user.reload.active).to be false
  end

  scenario "an inactive user can be reactivated" do
    administrator_user = create(:beis_user)
    user = create(:inactive_user)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Manage users"
    find("tr", text: user.name).click_link("Edit")

    choose I18n.t("form.user.active.active")
    click_on I18n.t("generic.button.submit")

    expect(user.reload.active).to be true
  end
end
