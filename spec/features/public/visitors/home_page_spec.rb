RSpec.feature "Home page" do
  scenario "visit the home page" do
    visit root_path
    expect(page).to have_content(t("app.title"))
  end

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }
    after { logout }

    scenario "they are redirected to their organisation show page" do
      visit root_path
      expect(page.current_path).to eq home_path
    end
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    before { authenticate!(user: user) }
    after { logout }

    scenario "they are redirected to their organisation show page" do
      visit root_path
      expect(page.current_path).to eq home_path
    end
  end
end
