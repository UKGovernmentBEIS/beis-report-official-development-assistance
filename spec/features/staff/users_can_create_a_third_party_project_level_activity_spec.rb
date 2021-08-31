RSpec.feature "Users can create a third-party project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a project" do
      scenario "a new third party project cannot be added to the programme when a report does not exist" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation, parent: programme)

        visit activities_path
        click_on project.title
        click_on t("tabs.activity.children")

        expect(page).to_not have_button(t("action.activity.add_child"))
      end

      scenario "a new third party project can be added to the project" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation, extending_organisation: user.organisation, parent: programme)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)

        activity = build(:third_party_project_activity, :gcrf_funded,
          country_delivery_partners: ["National Council for the State Funding Agencies (CONFAP)"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,)

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_project_gcrf_activity_form(activity)

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        third_party_project = project.child_activities.last

        expect(third_party_project.organisation).to eq user.organisation

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
        expect(created_activity.gcrf_challenge_area).to eq(activity.gcrf_challenge_area)
        expect(created_activity.gcrf_strategic_area).to eq(activity.gcrf_strategic_area)
        expect(created_activity.covid19_related).to eq(activity.covid19_related)
        expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)
        expect(created_activity.oda_eligibility_lead).to eq(activity.oda_eligibility_lead)
        expect(created_activity.uk_dp_named_contact).to eq(activity.uk_dp_named_contact)
      end

      context "without an editable report" do
        scenario "a new third party project cannot be added" do
          programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
          project = create(:project_activity, :gcrf_funded, organisation: user.organisation, extending_organisation: user.organisation, parent: programme)

          visit activities_path

          click_on(project.title)
          click_on t("tabs.activity.children")

          expect(page).to have_no_button t("action.activity.add_child")
        end
      end
    end
  end
end
