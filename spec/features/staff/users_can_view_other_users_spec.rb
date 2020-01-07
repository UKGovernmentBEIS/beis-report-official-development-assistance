require "rails_helper"

RSpec.feature "users can view other users" do
  let(:user) { create(:user) }

  before do
    authenticate!(user: user)
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit users_path
      expect(current_path).to eq(root_path)
    end
  end

  scenario "a user can be viewed" do
    visit users_path

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(user.email)
    expect(page).to have_content(user.role_name)

    # Navigate to the individual user page
    within(".users") do
      click_on(I18n.t("generic.link.show"))
    end

    expect(page).to have_content(I18n.t("page_title.users.show"))
    expect(page).to have_content(user.name)
    expect(page).to have_content(user.email)
    expect(page).to have_content(user.role_name)
  end

  scenario "can go back to the previous page" do
    user = create(:user)

    visit user_path(user)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(users_path)
  end
end
