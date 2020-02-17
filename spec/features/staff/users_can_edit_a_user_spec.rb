require "rails_helper"

RSpec.feature "Editing a user" do
  let!(:user) { create(:administrator, organisation: create(:organisation)) }

  before do
    stub_auth0_token_request
  end

  scenario "the role can be changed" do
    administrator_user = create(:administrator)
    authenticate!(user: administrator_user)

    visit organisation_path(administrator_user.organisation)
    click_on "Manage users"

    expect(page).to have_content(user.name)

    find("tr", text: user.name).click_link("Edit")

    choose "Administrator"
    click_on "Submit"

    expect(user.reload.role).to eql("administrator")
  end
end
