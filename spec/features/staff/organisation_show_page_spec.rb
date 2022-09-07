RSpec.feature "Organisation show page" do
  let(:partner_org_user) { create(:delivery_partner_user) }
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

        expect(page).to have_link t("page_content.organisation.button.edit_details"), href: edit_organisation_path(beis_user.organisation)
      end
    end
  end

  context "when signed in as a partner organisation user" do
    before do
      authenticate!(user: partner_org_user)
    end

    scenario "they do not see the edit details button" do
      visit organisation_path(partner_org_user.organisation)

      expect(page).not_to have_link t("page_content.organisation.button.edit_details"), href: edit_organisation_path(partner_org_user.organisation)
    end
  end
end
