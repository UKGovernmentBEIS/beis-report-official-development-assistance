RSpec.feature "Users can create a project" do
  context "when they are a delivery parther" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a programme" do
      scenario "a new project cannot be added to the programme when a report does not exist" do
        programme_activity = create(:programme_activity, :newton_funded, extending_organisation: user.organisation)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)
        click_on t("tabs.activity.children")

        expect(page).to have_no_button(t("action.activity.add_child"))
      end

      scenario "a new project can be added to the programme" do
        programme = create(:programme_activity, :newton_funded, extending_organisation: user.organisation)
        report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        activity = build(:project_activity, :newton_funded,
          country_delivery_partners: ["National Council for the State Funding Agencies (CONFAP)"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,)

        visit activities_path
        click_on programme.title
        click_on t("tabs.activity.children")
        click_on t("action.activity.add_child")

        fill_in_identifier_step(activity)
        fill_in_purpose_step(activity)
        fill_in_objectives_step(activity)
        fill_in_sector_category_step(activity)
        fill_in_sector_step(activity)
        fill_in_call_details(activity)
        fill_in_call_applications(activity)
        fill_in_programme_status(activity)
        fill_in_country_delivery_partners(activity)
        fill_in_dates(activity)
        fill_in_benefitting_countries(activity)
        fill_in_gdi(activity)
        fill_in_aid_type(activity)
        fill_in_collaboration_type(activity)
        fill_in_sdgs_apply(activity)
        fill_in_fund_pillar(activity)
        fill_in_policy_markers(activity)
        fill_in_covid19_related(activity)
        fill_in_channel_of_delivery_code(activity)
        fill_in_oda_eligibility(activity)
        fill_in_oda_eligibility_lead(activity)
        fill_in_named_contact(activity)

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        project = programme.child_activities.last

        expect(project.organisation).to eq user.organisation

        # our new direct association between activity and report
        expect(project.originating_report).to eq(report)
        expect(report.new_activities).to eq([project])

        created_activity = Activity.order("created_at ASC").last

        expect(created_activity.title).to eq(activity.title)
        expect(created_activity.description).to eq(activity.description)
        expect(created_activity.objectives).to eq(activity.objectives)
        expect(created_activity.sector_category).to eq(activity.sector_category)
        expect(created_activity.sector).to eq(activity.sector)
        expect(created_activity.programme_status).to eq(activity.programme_status)
        expect(created_activity.planned_start_date).to eq(activity.planned_start_date)
        expect(created_activity.planned_end_date).to eq(activity.planned_end_date)
        expect(created_activity.actual_start_date).to eq(activity.actual_start_date)
        expect(created_activity.actual_end_date).to eq(activity.actual_end_date)
        expect(created_activity.country_delivery_partners).to eq(activity.country_delivery_partners)
        expect(created_activity.benefitting_countries).to eq(activity.benefitting_countries)
        expect(created_activity.gdi).to eq(activity.gdi)
        expect(created_activity.aid_type).to eq(activity.aid_type)
        expect(created_activity.collaboration_type).to eq(activity.collaboration_type)
        expect(created_activity.sdgs_apply).to eq(activity.sdgs_apply)
        expect(created_activity.sdg_1).to eq(activity.sdg_1)
        expect(created_activity.policy_marker_gender).to eq(activity.policy_marker_gender)
        expect(created_activity.policy_marker_climate_change_adaptation).to eq(activity.policy_marker_climate_change_adaptation)
        expect(created_activity.policy_marker_climate_change_mitigation).to eq(activity.policy_marker_climate_change_mitigation)
        expect(created_activity.policy_marker_biodiversity).to eq(activity.policy_marker_biodiversity)
        expect(created_activity.policy_marker_desertification).to eq(activity.policy_marker_desertification)
        expect(created_activity.policy_marker_disability).to eq(activity.policy_marker_disability)
        expect(created_activity.policy_marker_disaster_risk_reduction).to eq(activity.policy_marker_disaster_risk_reduction)
        expect(created_activity.policy_marker_nutrition).to eq(activity.policy_marker_nutrition)
        expect(created_activity.channel_of_delivery_code).to eq(activity.channel_of_delivery_code)
        expect(created_activity.covid19_related).to eq(activity.covid19_related)
        expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)
        expect(created_activity.oda_eligibility_lead).to eq(activity.oda_eligibility_lead)
        expect(created_activity.uk_dp_named_contact).to eq(activity.uk_dp_named_contact)
      end

      scenario "can create a new child activity for a given programme" do
        gcrf = create(:fund_activity, :gcrf)
        programme = create(:programme_activity, parent: gcrf, extending_organisation: user.organisation)
        _report = create(:report, :active, fund: gcrf, organisation: user.organisation)

        visit organisation_activity_path(programme.organisation, programme)

        click_link t("tabs.activity.children")
        click_button t("action.activity.add_child")
        fill_in "activity[delivery_partner_identifier]", with: "foo"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.purpose", level: "project (level C)")
      end

      scenario "the activity date shows an error message if an invalid date is entered" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.extending_organisation, programme)
        click_on t("action.activity.add_child")

        fill_in "activity[delivery_partner_identifier]", with: "no-country-selected"
        click_button t("form.button.activity.submit")
        fill_in "activity[title]", with: "My title"
        fill_in "activity[description]", with: "My description"
        click_button t("form.button.activity.submit")
        fill_in "activity[objectives]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")
        choose "Basic Education"
        click_button t("form.button.activity.submit")
        choose "School feeding"
        click_button t("form.button.activity.submit")
        choose "No"
        click_button t("form.button.activity.submit")
        choose "Delivery"
        click_button t("form.button.activity.submit")
        fill_in "activity[planned_start_date(3i)]", with: "01"
        fill_in "activity[planned_start_date(2i)]", with: "12"
        fill_in "activity[planned_start_date(1i)]", with: "2020"
        fill_in "activity[planned_end_date(3i)]", with: "01"
        fill_in "activity[planned_end_date(2i)]", with: "15"
        fill_in "activity[planned_end_date(1i)]", with: "2021"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_end_date.invalid")
      end
    end
  end
end
