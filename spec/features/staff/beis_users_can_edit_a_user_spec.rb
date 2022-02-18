require "rails_helper"

RSpec.feature "BEIS users can edit other users" do
  let!(:user) { create(:delivery_partner_user, organisation: create(:delivery_partner_organisation)) }

  scenario "the email address is disabled" do
    user = create(:beis_user)
    authenticate!(user: user)

    target_user = create(:delivery_partner_user, name: "Old Name", email: "old@example.com")

    visit organisation_path(user.organisation)
    click_on(t("page_title.users.index"))

    find("tr", text: target_user.name).click_link("Edit")

    email_field = find("input[name='user[email]']")
    expect(email_field).to be_disabled
  end

  scenario "the user's name can be updated" do
    user = create(:beis_user)
    authenticate!(user: user)

    target_user = create(:delivery_partner_user, name: "Old Name", email: "old@example.com")

    # Navigate to the users page
    visit users_path

    expect(page).to have_content(t("page_title.users.index"))

    # Find the target user and click on edit button

    find("tr", text: target_user.name).click_link("Edit")

    # Fill out the form
    fill_in "user[name]", with: "New Name"

    # Submit the form
    click_button t("form.button.user.submit")

    # Verify the user was updated
    expect(page).to have_content("New Name")
  end

  scenario "an active user can be deactivated" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)

    # Navigate to the users page
    visit users_path

    find("tr", text: user.name).click_link("Edit")

    choose "Deactivate"
    click_on t("default.button.submit")

    expect(user.reload.active).to be false
  end

  scenario "an inactive user can be reactivated" do
    administrator_user = create(:beis_user)
    user = create(:inactive_user, organisation: create(:delivery_partner_organisation))
    authenticate!(user: administrator_user)

    # Navigate to the users page
    visit users_path

    find("tr", text: user.name).click_link("Edit")

    choose "Activate"
    click_on t("default.button.submit")

    expect(user.reload.active).to be true
  end
end
