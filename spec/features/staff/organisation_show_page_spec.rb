feature "Organisation show page" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }

  context "when signed in as a BEIS user" do
    context "when viewing the BEIS oganisation" do
      before do
        authenticate!(user: beis_user)
        visit organisation_path(beis_user.organisation)
      end

      scenario "they see the organisation details" do
        expect(page).to have_content beis_user.organisation.name
        expect(page).to have_content beis_user.organisation.iati_reference
      end

      scenario "they see a edit details button" do
        expect(page).to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(beis_user.organisation)
      end
    end

    context "when viewing a delivery partners organisation" do
      scenario "they do not see funds or the create fund button" do
        visit organisation_path(delivery_partner_user.organisation)

        expect(page).not_to have_button I18n.t("page_content.organisation.button.create_activity")
        expect(page).not_to have_content "Funds"
      end
    end
  end

  context "when signed in as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
      visit organisation_path(delivery_partner_user.organisation)
    end

    scenario "they do not see the edit detials button" do
      expect(page).not_to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(delivery_partner_user.organisation)
    end
  end
end
