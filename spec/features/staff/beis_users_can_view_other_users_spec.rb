require "rails_helper"

RSpec.feature "BEIS users can can view other users" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit users_path
      expect(current_path).to eq(root_path)
    end
  end

  let(:user) { create(:beis_user) }

  before do
    authenticate!(user: user)
  end

  scenario "an active user can be viewed" do
    another_user = create(:administrator)

    # Navigate from the landing page
    visit organisation_path(user.organisation)
    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # Navigate to the users page
    expect(page).to have_content(I18n.t("page_title.users.index"))
    expect(page).to have_content(another_user.name)
    expect(page).to have_content(another_user.email)
    expect(page).to have_content(another_user.organisation.name)
    expect(page).to have_content(I18n.t("form.user.active.true"))

    # Navigate to the individual user page
    within(".users") do
      find("tr", text: another_user.name).click_link("Show")
    end

    expect(page).to have_content(I18n.t("page_title.users.show"))
    expect(page).to have_content(another_user.name)
    expect(page).to have_content(another_user.email)
  end

  scenario "an inactive user can be viewed" do
    another_user = create(:inactive_user)

    # Navigate from the landing page
    visit organisation_path(user.organisation)
    click_on(I18n.t("page_content.dashboard.button.manage_users"))

    # The details include whether the user is active
    expect(page).to have_content(I18n.t("form.user.active.false"))

    # Navigate to the individual user page
    within(".users") do
      find("tr", text: another_user.name).click_link("Show")
    end

    expect(page).to have_content(I18n.t("form.user.active.false"))
  end

  scenario "can go back to the previous page" do
    another_user = create(:administrator)

    visit user_path(another_user)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(users_path)
  end
end
