RSpec.describe "Users can create a planned disbursement" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can add a planned disbursement" do
      project = create(:project_activity, organisation: user.organisation)

      visit activities_path

      click_on project.title

      expect(page).to have_content I18n.t("page_content.activity.planned_disbursements")

      click_on I18n.t("page_content.planned_disbursements.button.create")

      expect(page).to have_content I18n.t("page_title.planned_disbursement.new")

      choose I18n.t("form.label.planned_disbursement.planned_disbursement_type_options.original.name")
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
      click_button I18n.t("default.button.submit")

      expect(page).to have_current_path organisation_activity_financials_path(user.organisation, project)
      expect(page).to have_content I18n.t("action.planned_disbursement.create.success")
    end

    scenario "the action is recorded with public_activity" do
      activity = create(:project_activity, organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path

        click_on(activity.title)

        click_on(I18n.t("page_content.planned_disbursements.button.create"))

        fill_in_planned_disbursement_form

        planned_disbursement = PlannedDisbursement.last
        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "planned_disbursement.create"
        expect(auditable_event.owner_id).to eq user.id
        expect(auditable_event.trackable_id).to eq planned_disbursement.id
      end
    end

    context "when the delivery partner is a government organisation" do
      context "and the activity is a project" do
        it "pre fills the providing organisation details with those of BEIS" do
          beis = create(:beis_organisation)
          government_devlivery_partner = create(:delivery_partner_organisation, organisation_type: "10")
          user.update(organisation: government_devlivery_partner)
          project = create(:project_activity, organisation: user.organisation)

          visit activities_path
          click_on project.title
          click_on I18n.t("page_content.planned_disbursements.button.create")

          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_name"), with: beis.name)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_type"), with: beis.organisation_type)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_reference"), with: beis.iati_reference)
        end
      end

      context "and the activity is a third-party project" do
        it "pre fills the providing organisation details with those of BEIS" do
          beis = create(:beis_organisation)
          government_devlivery_partner = create(:delivery_partner_organisation, organisation_type: "10")
          user.update(organisation: government_devlivery_partner)
          project = create(:third_party_project_activity, organisation: user.organisation)

          visit activities_path
          click_on project.title
          click_on I18n.t("page_content.planned_disbursements.button.create")

          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_name"), with: beis.name)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_type"), with: beis.organisation_type)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_reference"), with: beis.iati_reference)
        end
      end
    end

    context "when the delivery partner is a non-government organisation" do
      context "and the activity is a project" do
        it "pre fills the providing organisation details with those of BEIS" do
          beis = create(:beis_organisation)
          government_devlivery_partner = create(:delivery_partner_organisation, organisation_type: "10")
          user.update(organisation: government_devlivery_partner)
          project = create(:project_activity, organisation: user.organisation)

          visit activities_path
          click_on project.title
          click_on I18n.t("page_content.planned_disbursements.button.create")

          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_name"), with: beis.name)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_type"), with: beis.organisation_type)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_reference"), with: beis.iati_reference)
        end
      end
      context "and the activity is a third-party project" do
        it "pre fills the providing organisation detauls with those of the delivery partner" do
          non_government_devlivery_partner = create(:delivery_partner_organisation, organisation_type: "22")
          user.update(organisation: non_government_devlivery_partner)
          project = create(:third_party_project_activity, organisation: user.organisation)

          visit activities_path
          click_on project.title
          click_on I18n.t("page_content.planned_disbursements.button.create")

          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_name"), with: non_government_devlivery_partner.name)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_type"), with: non_government_devlivery_partner.organisation_type)
          expect(page).to have_field(I18n.t("form.label.planned_disbursement.providing_organisation_reference"), with: non_government_devlivery_partner.iati_reference)
        end
      end
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }

    scenario "they cannot add a planned disbursement" do
      project = create(:project_activity)
      visit activities_path
      click_on project.parent.title
      click_on I18n.t("tabs.activity.details")
      click_on project.title

      expect(page).not_to have_link I18n.t("page_content.planned_disbursements.button.create"), href: new_activity_planned_disbursement_path(project)

      visit new_activity_planned_disbursement_path(project)

      expect(page).to have_content I18n.t("page_title.errors.not_authorised")
    end
  end
end
