RSpec.feature "users can view a home page" do
  context "when not signed in" do
    scenario "they cannot reach the home page and are redirected to the sign in" do
      visit home_path

      expect(page).to have_button("Sign in")
    end
  end

  context "when a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate! user: beis_user
    end

    scenario "they see the home page" do
      visit home_path

      expect(page.current_path).to eql home_path
    end
  end

  context "when a delivery partner  user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate! user: delivery_partner_user
    end

    scenario "they are redirected to their home page" do
      visit home_path

      expect(page.current_path).to eql home_path
    end
  end
end
