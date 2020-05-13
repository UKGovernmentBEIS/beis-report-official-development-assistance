RSpec.describe "Users can create a planned disbursement" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can add a planned disbursement" do
      project = create(:project_activity, organisation: user.organisation)
      visit organisation_path(user.organisation)
      click_on project.title

      expect(page).to have_content I18n.t("page_content.activity.planned_disbursements")

      click_on I18n.t("page_content.planned_disbursements.button.create")

      expect(page).to have_content I18n.t("page_title.planned_disbursement.new")

      choose I18n.t("activerecord.attributes.planned_disbursement.planned_disbursement_type.original.name")
      fill_in "planned_disbursement[period_start_date(3i)]", with: "01"
      fill_in "planned_disbursement[period_start_date(2i)]", with: "01"
      fill_in "planned_disbursement[period_start_date(1i)]", with: "2020"
      fill_in "planned_disbursement[period_end_date(3i)]", with: "31"
      fill_in "planned_disbursement[period_end_date(2i)]", with: "12"
      fill_in "planned_disbursement[period_end_date(1i)]", with: "2020"
      select "Pound Sterling", from: "planned_disbursement[currency]"
      fill_in "planned_disbursement[value]", with: "1000.00"
      fill_in "planned_disbursement[providing_organisation_name]", with: "org"
      select "Government", from: "planned_disbursement[providing_organisation_type]"
      fill_in "planned_disbursement[receiving_organisation_name]", with: "another org"
      select "Other Public Sector", from: "planned_disbursement[receiving_organisation_type]"
      click_button I18n.t("generic.button.submit")

      expect(page).to have_current_path organisation_activity_path(user.organisation, project)
      expect(page).to have_content I18n.t("form.planned_disbursement.create.success")
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }

    scenario "they cannot add a planned disbursement" do
      project = create(:project_activity, organisation: beis_user.organisation)
      visit organisation_path(beis_user.organisation)
      click_on project.title

      expect(page).not_to have_link I18n.t("page_content.planned_disbursements.button.create"), href: new_activity_planned_disbursement_path(project)

      visit new_activity_planned_disbursement_path(project)

      expect(page).to have_content I18n.t("page_title.errors.not_authorised")
    end
  end
end
