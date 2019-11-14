require "rails_helper"

RSpec.feature "users can view other users" do
  let(:user) { create(:user) }

  before(:each) do
    stub_authenticated_session(uid: user.identifier, name: user.name, email: user.email)
  end

  scenario "a user can be viewed" do
    visit users_path

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(user.email)

    # Navigate to the individual user page
    within(".users") do
      click_on(I18n.t("generic.link.show"))
    end

    expect(page).to have_content(I18n.t("page_title.users.show"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(user.email)
  end
end
