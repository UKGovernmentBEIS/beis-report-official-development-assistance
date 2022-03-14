require "rails_helper"

RSpec.feature "BEIS users can can view other users" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit users_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:beis_user) }

    before do
      authenticate!(user: user)
    end

    scenario "an active user can be viewed" do
      another_user = create(:administrator)

      # Navigate from the landing page
      visit organisation_path(user.organisation)
      click_on("Users")

      # Navigate to the users page
      expect(page).to have_content("Users")
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)
      expect(page).to have_content(another_user.organisation.name)
      expect(page).to have_content("Yes")

      # Navigate to the individual user page
      within(".users") do
        find("tr", text: another_user.name).click_link("View")
      end

      expect(page).to have_content("User")
      expect(page).to have_content(another_user.name)
      expect(page).to have_content(another_user.email)
    end

    scenario "users are grouped by their organisation name in alphabetical order" do
      a_organisation = create(:delivery_partner_organisation, name: "A Organisation")
      b_organisation = create(:delivery_partner_organisation, name: "B Organisation")

      a1_user = create(:administrator, organisation: a_organisation)
      a2_user = create(:administrator, organisation: a_organisation)
      b1_user = create(:administrator, organisation: b_organisation)
      b2_user = create(:administrator, organisation: b_organisation)

      # Navigate from the landing page
      visit organisation_path(user.organisation)
      click_on("Users")

      expected_array = [
        a1_user.organisation.name,
        a2_user.organisation.name,
        b1_user.organisation.name,
        b2_user.organisation.name,
        user.organisation.name
      ].sort

      expect(page.all("td.organisation").collect(&:text)).to match_array(expected_array)
    end

    scenario "an inactive user can be viewed" do
      another_user = create(:inactive_user)

      # Navigate from the landing page
      visit organisation_path(user.organisation)
      click_on("Users")

      # The details include whether the user is active
      expect(page).to have_content("No")

      # Navigate to the individual user page
      within(".users") do
        find("tr", text: another_user.name).click_link("View")
      end

      expect(page).to have_content("No")
    end
  end
end
