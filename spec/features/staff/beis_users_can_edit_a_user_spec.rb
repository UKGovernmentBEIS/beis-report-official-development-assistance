require "rails_helper"

RSpec.feature "BEIS users can editing other users" do
  let!(:user) { create(:delivery_partner_user, organisation: create(:delivery_partner_organisation)) }

  before do
    stub_auth0_token_request
  end

  scenario "the email address is disabled" do
    user = create(:beis_user)
    authenticate!(user: user)

    target_user = create(:delivery_partner_user, name: "Old Name", email: "old@example.com")

    visit organisation_path(user.organisation)
    click_on("Users")

    find("tr", text: target_user.name).click_link("Edit")

    email_field = find("input[name='user[email]']")
    expect(email_field).to be_disabled
  end

  scenario "the details of the user can be updated" do
    user = create(:beis_user)
    authenticate!(user: user)

    target_user = create(:delivery_partner_user, name: "Old Name", email: "old@example.com")

    updated_name = "New Name"

    stub_auth0_update_user_request(
      auth0_identifier: target_user.identifier,
      name: updated_name,
      email: target_user.email
    )

    # Navigate from the landing page
    visit organisation_path(user.organisation)

    click_on("Users")

    # Navigate to the users page
    expect(page).to have_content("Users")

    # Find the target user and click on edit button

    find("tr", text: target_user.name).click_link("Edit")

    # Fill out the form
    fill_in "user[name]", with: updated_name

    # Submit the form
    click_button "Submit"

    # Verify the user was updated
    expect(page).to have_content(updated_name)
  end

  scenario "an active user can be deactivated" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Users"
    find("tr", text: user.name).click_link("Edit")

    choose "Deactivate"
    click_on "Submit"

    expect(user.reload.active).to be false
  end

  scenario "an inactive user can be reactivated" do
    administrator_user = create(:beis_user)
    user = create(:inactive_user, organisation: create(:delivery_partner_organisation))
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Users"
    find("tr", text: user.name).click_link("Edit")

    choose "Activate"
    click_on "Submit"

    expect(user.reload.active).to be true
  end
end
