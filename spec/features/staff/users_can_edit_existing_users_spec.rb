require "rails_helper"

RSpec.feature "Editing a user" do
  before do
    authenticate!(user: build_stubbed(:user, role: :fund_manager))
    stub_auth0_token_request
  end

  scenario "the details of the user can be updated" do
    target_user = create(:administrator, name: "Old Name", email: "old@example.com")

    updated_name = "New Name"
    updated_email = "new@example.com"

    stub_auth0_update_user_request(
      auth0_identifier: target_user.identifier,
      email: updated_email,
      name: updated_name
    )

    # Navigate from the landing page
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))

    # Click on edit button
    click_on(I18n.t("generic.link.edit"))

    # Fill out the form
    fill_in "user[name]", with: updated_name
    fill_in "user[email]", with: updated_email

    # Submit the form
    click_button I18n.t("form.user.submit")

    # Verify the user was updated
    expect(page).to have_content(updated_name)
    expect(page).to have_content(updated_email)
  end
end
