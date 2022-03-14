RSpec.feature "Organisation show page" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  context "when signed in as a BEIS user" do
    context "when viewing the BEIS organisation" do
      before do
        authenticate!(user: beis_user)
      end

      scenario "they see the organisation details" do
        visit organisation_path(beis_user.organisation)

        expect(page).to have_content beis_user.organisation.name
        expect(page).to have_content beis_user.organisation.iati_reference
      end

      scenario "they see a edit details button" do
        visit organisation_path(beis_user.organisation)

        expect(page).to have_link "Edit details", href: edit_organisation_path(beis_user.organisation)
      end
    end
  end

  context "when signed in as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they do not see the edit details button" do
      visit organisation_path(delivery_partner_user.organisation)

      expect(page).not_to have_link "Edit details", href: edit_organisation_path(delivery_partner_user.organisation)
    end
  end
end
