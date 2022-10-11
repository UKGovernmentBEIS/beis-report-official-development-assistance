require "rails_helper"

RSpec.feature "Users can sign out" do
  after { logout }

  scenario "success" do
    # Given a user exists
    user = create(:administrator)
    # And is logged in
    authenticate!(user: user)

    # When they sign out
    visit root_path
    click_on "Sign out"

    # Then they should be logged out
    expect(page).to have_content("Signed out successfully.")
  end
end
