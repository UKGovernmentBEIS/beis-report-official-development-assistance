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
    click_on(t("page_title.users.index"))

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

    click_on(t("page_title.users.index"))

    # Navigate to the users page
    expect(page).to have_content(t("page_title.users.index"))

    # Find the target user and click on edit button

    find("tr", text: target_user.name).click_link("Edit")

    # Fill out the form
    fill_in "user[name]", with: updated_name

    # Submit the form
    click_button t("form.button.user.submit")

    # Verify the user was updated
    expect(page).to have_content(updated_name)
  end

  scenario "the role can be changed" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on t("page_title.users.index")

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
    click_on t("page_title.users.index")
    find("tr", text: user.name).click_link("Edit")

    choose t("form.user.active.inactive")
    click_on t("default.button.submit")

    expect(user.reload.active).to be false
  end

  scenario "an inactive user can be reactivated" do
    administrator_user = create(:beis_user)
    user = create(:inactive_user, organisation: create(:delivery_partner_organisation))
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on t("page_title.users.index")
    find("tr", text: user.name).click_link("Edit")

    choose t("form.user.active.active")
    click_on t("default.button.submit")

    expect(user.reload.active).to be true
  end

  scenario "user update is tracked with public_activity" do
    administrator_user = create(:beis_user)
    authenticate!(user: administrator_user)
    target_user = create(:delivery_partner_user, name: "Old Name", email: "old@example.com")

    updated_name = "New Name"

    stub_auth0_update_user_request(
      auth0_identifier: target_user.identifier,
      name: updated_name,
      email: target_user.email
    )

    PublicActivity.with_tracking do
      visit organisation_path(user.organisation)

      click_on(t("page_title.users.index"))

      find("tr", text: target_user.name).click_link("Edit")

      fill_in "user[name]", with: updated_name

      click_button t("form.button.user.submit")

      auditable_event = PublicActivity::Activity.find_by(trackable_id: target_user.id)
      expect(auditable_event.key).to eq "user.update"
      expect(auditable_event.owner_id).to eq administrator_user.id
    end
  end
end
