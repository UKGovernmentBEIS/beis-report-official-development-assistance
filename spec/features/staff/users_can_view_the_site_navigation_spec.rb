RSpec.feature "Users can view the site navigation" do
  context "when the user is not signed in" do
    it "does not show the navigation" do
      activity = create(:project_activity)

      visit organisation_path(activity.organisation)

      expect(page).not_to have_css ".govuk-header__navigation"
      expect(page).not_to have_link organisation_path(activity.organisation)
    end
  end

  context "when the user is signed in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    it "shows the appropriate naviation" do
      visit organisation_path(user.organisation)

      expect(page).to have_css ".govuk-header__navigation"
      expect(page).to have_link "Home", href: home_path
      expect(page).to have_link "Reports", href: reports_path
      expect(page).not_to have_link "Organisations", href: organisations_path, class: "govuk-header__link"
      expect(page).not_to have_link "Users", href: users_path
    end
  end

  context "when the user is signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    it "shows the appropriate naviation" do
      visit organisation_path(user.organisation)

      expect(page).to have_css ".govuk-header__navigation"
      expect(page).to have_link "Home", href: home_path
      expect(page).to have_link "Reports", href: reports_path
      expect(page).to have_link "Organisations", href: organisations_path
      expect(page).to have_link "Users", href: users_path
    end
  end
end
