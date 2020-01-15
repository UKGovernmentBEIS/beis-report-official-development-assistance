require "rails_helper"

RSpec.feature "Editing a user" do
  let!(:user) { create(:delivery_partner, organisation: create(:organisation)) }

  before do
    stub_auth0_token_request
    authenticate!(user: build_stubbed(:administrator))
  end

  scenario "the role can be changed" do
    visit dashboard_path
    click_on "Manage users"

    expect(page).to have_content(user.name)

    find("tr", text: user.name).click_link("Edit")

    choose "Fund manager"
    click_on "Submit"

    expect(user.reload.role).to eql "fund_manager"
  end
end
