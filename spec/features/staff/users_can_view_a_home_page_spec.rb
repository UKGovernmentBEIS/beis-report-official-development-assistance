RSpec.feature "users can view a home page" do
  context "when not signed in" do
    scenario "they cannot reach the home page and are redirected to the sign in" do
      visit home_path

      expect(page).to have_link("Sign in")
    end
  end

  context "when a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let!(:partner_organisation) { create(:delivery_partner_organisation) }

    before do
      authenticate! user: beis_user
    end

    scenario "they see the home page and the right content" do
      visit home_path

      expect(page.current_path).to eql home_path
      expect(page).to have_button("Search")
      expect(page).to have_table("Partner organisations")
      expect(page).to have_content(partner_organisation.name)
    end
  end

  context "when a partner organisation user" do
    let(:partner_org_user) { create(:delivery_partner_user) }
    let!(:programme) { create(:programme_activity, extending_organisation: partner_org_user.organisation) }

    before do
      authenticate! user: partner_org_user
    end

    scenario "they see their home page and the right content" do
      visit home_path

      expect(page.current_path).to eql home_path
      expect(page).to have_content t("page_content.reports.title")
      expect(page).to have_button("Search")
      expect(page).to have_content(programme.title)
    end
  end
end
