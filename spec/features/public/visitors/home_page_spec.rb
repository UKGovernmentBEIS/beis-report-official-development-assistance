RSpec.feature "Home page" do
  scenario "visit the home page" do
    visit root_path
    expect(page).to have_content(t("app.title"))
  end

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "they are redirected to their organisation show page" do
      visit root_path
      expect(page.current_path).to eq organisation_path(user.organisation)
    end
  end

  context "when signed in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "they are redirected to their organisation show page" do
      visit root_path
      expect(page.current_path).to eq organisation_path(user.organisation)
    end
  end

  context "when signed in as a user who is not active" do
    let(:user) { create(:delivery_partner_user, active: false) }
    before { authenticate!(user: user) }

    scenario "they are shown the start page" do
      visit root_path
      expect(page).to have_button(t("header.link.sign_in"))
    end
  end
end
