RSpec.feature "Users can manage the implementing organisations" do
  context "when they are signed in as a delivery partner" do
    let(:delivery_partner) { create(:organisation) }
    let(:project) { create(:project_activity, organisation: delivery_partner) }

    before { authenticate!(user: create(:delivery_partner_user, organisation: delivery_partner)) }

    scenario "they can add an implementing organisation" do
      other_public_sector_organisation = ImplementingOrganisation.new(name: "Other public sector organisation", organisation_type: "10", reference: "GB-COH-123456")

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content I18n.t("page_content.activity.implementing_organisation.button.new")
      click_on I18n.t("page_content.activity.implementing_organisation.button.new")

      expect(page).to have_field I18n.t("form.label.implementing_organisation.name")
      expect(page).to have_select I18n.t("form.label.implementing_organisation.organisation_type")
      expect(page).to have_field I18n.t("form.label.implementing_organisation.reference")

      fill_in I18n.t("form.label.implementing_organisation.name"), with: other_public_sector_organisation.name
      select("Other Public Sector", from: I18n.t("form.label.implementing_organisation.organisation_type"))
      fill_in I18n.t("form.label.implementing_organisation.reference"), with: other_public_sector_organisation.reference
      click_on I18n.t("default.button.submit")

      expect(current_path).to eq organisation_activity_details_path(project.organisation, project)
      expect(page).to have_content I18n.t("action.implementing_organisation.create.success")

      expect(page).to have_content other_public_sector_organisation.name
      expect(page).to have_content other_public_sector_organisation.reference
    end

    scenario "they can edit an implementing organisation" do
      other_public_sector_organisation = ImplementingOrganisation.new(name: "Other public sector organisation", organisation_type: "70", reference: "GB-COH-123456")
      project.implementing_organisations << other_public_sector_organisation

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content other_public_sector_organisation.name
      expect(page).to have_content other_public_sector_organisation.reference

      within "##{other_public_sector_organisation.id}" do
        click_on "Edit"
      end

      expect(find_field(I18n.t("form.label.implementing_organisation.name")).value).to eq other_public_sector_organisation.name

      fill_in I18n.t("form.label.implementing_organisation.name"), with: "It is a charity"
      click_on I18n.t("default.button.submit")

      expect(page).to have_content I18n.t("action.implementing_organisation.update.success")
      expect(page).to have_content "It is a charity"
    end
  end

  context "when they are signed in as a BEIS user" do
    let(:delivery_partner) { create(:organisation) }
    let(:project) { create(:project_activity, organisation: delivery_partner) }

    before { authenticate!(user: create(:beis_user)) }

    scenario "they can view implementing organisations" do
      other_public_sector_organisation = ImplementingOrganisation.new(name: "Other public sector organisation", organisation_type: "70", reference: "GB-COH-123456")
      project.implementing_organisations << other_public_sector_organisation

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content other_public_sector_organisation.name
      expect(page).to have_content other_public_sector_organisation.reference
    end

    scenario "they cannot edit implementing organisations" do
      other_public_sector_organisation = ImplementingOrganisation.new(name: "Other public sector organisation", organisation_type: "70", reference: "GB-COH-123456")
      project.implementing_organisations << other_public_sector_organisation

      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_link I18n.t("default.link.edit"), href: edit_activity_implementing_organisation_path(project, other_public_sector_organisation)
    end

    scenario "they cannot add implementing organisations" do
      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_button I18n.t("page_content.activity.implementing_organisation.button.new")
    end
  end
end
