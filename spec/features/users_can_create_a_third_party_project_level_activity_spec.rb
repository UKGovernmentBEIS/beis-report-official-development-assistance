RSpec.feature "Users can create a third-party project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:partner_organisation_user) }
    before { authenticate!(user: user) }
    after { logout }

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
        _report = create(:report, :active, organisation: user.organisation, fund: project.associated_fund)

        activity = build(:third_party_project_activity, :gcrf_funded,
          country_partner_organisations: ["National Council for the State Funding Agencies (CONFAP)"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5)

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        form = ActivityForm.new(activity: activity, level: "project", fund: "gcrf")
        form.complete!

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(project.child_activities.last)

        expect(created_activity.organisation).to eq user.organisation
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
        expect(created_activity.benefitting_countries).to match_array(activity.benefitting_countries)
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
        expect(created_activity.uk_po_named_contact).to eq(activity.uk_po_named_contact)
      end

      scenario "a new third party project can be added to an ISPF ODA project" do
        programme = create(:programme_activity, :ispf_funded, extending_organisation: user.organisation)

        project = create(:project_activity, :ispf_funded,
          organisation: user.organisation,
          extending_organisation: user.organisation,
          parent: programme,
          is_oda: true)

        _report = create(:report, :active, organisation: user.organisation, fund: project.associated_fund)

        implementing_organisation = create(:implementing_organisation)

        activity = build(:third_party_project_activity,
          parent: project,
          is_oda: true,
          ispf_partner_countries: ["IN"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,
          ispf_theme: 1,
          implementing_organisations: [implementing_organisation])

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        form = ActivityForm.new(activity: activity, level: "project", fund: "ispf")
        form.complete!

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(project.child_activities.last)

        expect(created_activity.organisation).to eq(user.organisation)
        expect(created_activity.is_oda).to eq(activity.is_oda)
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
        expect(created_activity.ispf_partner_countries).to match_array(activity.ispf_partner_countries)
        expect(created_activity.benefitting_countries).to match_array(activity.benefitting_countries)
        expect(created_activity.gdi).to eq(activity.gdi)
        expect(created_activity.aid_type).to eq(activity.aid_type)
        expect(created_activity.collaboration_type).to eq(activity.collaboration_type)
        expect(created_activity.sdgs_apply).to eq(activity.sdgs_apply)
        expect(created_activity.sdg_1).to eq(activity.sdg_1)
        expect(created_activity.ispf_theme).to eq(activity.ispf_theme)
        expect(created_activity.policy_marker_gender).to eq(activity.policy_marker_gender)
        expect(created_activity.policy_marker_climate_change_adaptation).to eq(activity.policy_marker_climate_change_adaptation)
        expect(created_activity.policy_marker_climate_change_mitigation).to eq(activity.policy_marker_climate_change_mitigation)
        expect(created_activity.policy_marker_biodiversity).to eq(activity.policy_marker_biodiversity)
        expect(created_activity.policy_marker_desertification).to eq(activity.policy_marker_desertification)
        expect(created_activity.policy_marker_disability).to eq(activity.policy_marker_disability)
        expect(created_activity.policy_marker_disaster_risk_reduction).to eq(activity.policy_marker_disaster_risk_reduction)
        expect(created_activity.policy_marker_nutrition).to eq(activity.policy_marker_nutrition)
        expect(created_activity.covid19_related).to eq(activity.covid19_related)
        expect(created_activity.channel_of_delivery_code).to eq(activity.channel_of_delivery_code)
        expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)
        expect(created_activity.oda_eligibility_lead).to eq(activity.oda_eligibility_lead)
        expect(created_activity.uk_po_named_contact).to eq(activity.uk_po_named_contact)
        expect(created_activity.implementing_organisations).to eq(activity.implementing_organisations)
      end

      scenario "a new third party project can be added to an ISPF non-ODA project" do
        programme = create(:programme_activity, :ispf_funded, extending_organisation: user.organisation, is_oda: false)

        project = create(:project_activity, :ispf_funded,
          organisation: user.organisation,
          extending_organisation: user.organisation,
          parent: programme,
          is_oda: false)

        _report = create(:report, :active, organisation: user.organisation, fund: project.associated_fund)

        implementing_organisation = create(:implementing_organisation)

        activity = build(:third_party_project_activity,
          parent: project,
          is_oda: false,
          ispf_partner_countries: ["IN"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,
          ispf_theme: 1,
          implementing_organisations: [implementing_organisation])

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        form = ActivityForm.new(activity: activity, level: "project", fund: "ispf")
        form.complete!

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(project.child_activities.last)

        expect(created_activity.organisation).to eq(user.organisation)
        expect(created_activity.is_oda).to eq(activity.is_oda)
        expect(created_activity.title).to eq(activity.title)
        expect(created_activity.description).to eq(activity.description)
        expect(created_activity.sector_category).to eq(activity.sector_category)
        expect(created_activity.sector).to eq(activity.sector)
        expect(created_activity.programme_status).to eq(activity.programme_status)
        expect(created_activity.planned_start_date).to eq(activity.planned_start_date)
        expect(created_activity.planned_end_date).to eq(activity.planned_end_date)
        expect(created_activity.actual_start_date).to eq(activity.actual_start_date)
        expect(created_activity.actual_end_date).to eq(activity.actual_end_date)
        expect(created_activity.ispf_partner_countries).to match_array(activity.ispf_partner_countries)
        expect(created_activity.ispf_theme).to eq(activity.ispf_theme)
        expect(created_activity.uk_po_named_contact).to eq(activity.uk_po_named_contact)
        expect(created_activity.implementing_organisations).to eq(activity.implementing_organisations)
      end

      scenario "an ODA third-party project can be linked to an existing non-ODA third-party project" do
        implementing_organisation = create(:implementing_organisation)

        non_oda_programme = create(:programme_activity, :ispf_funded,
          is_oda: false,
          extending_organisation: user.organisation)
        _report = create(:report, :active, organisation: user.organisation, fund: non_oda_programme.associated_fund)
        non_oda_project = create(:project_activity, :ispf_funded,
          parent: non_oda_programme,
          organisation: user.organisation,
          extending_organisation: user.organisation,
          ispf_theme: 1)
        non_oda_3rdp_project = create(:third_party_project_activity, :ispf_funded,
          parent: non_oda_project)

        oda_programme = create(:programme_activity, :ispf_funded,
          is_oda: true,
          linked_activity: non_oda_programme,
          extending_organisation: user.organisation)
        oda_project = create(:project_activity, :ispf_funded,
          parent: oda_programme,
          organisation: user.organisation,
          extending_organisation: user.organisation,
          linked_activity: non_oda_project,
          ispf_theme: 1)

        oda_3rdp_project = build(:third_party_project_activity,
          parent: oda_project,
          is_oda: true,
          linked_activity_id: non_oda_3rdp_project.id,
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,
          ispf_theme: 1,
          implementing_organisations: [implementing_organisation])

        visit activities_path

        click_on(oda_project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        form = ActivityForm.new(activity: oda_3rdp_project, level: "project", fund: "ispf")
        form.complete!

        expect(page).to have_content t("action.third_party_project.create.success")

        created_activity = form.created_activity

        expect(created_activity.title).to eq(oda_3rdp_project.title)
        expect(created_activity.is_oda).to eq(oda_3rdp_project.is_oda)
        expect(created_activity.linked_activity).to eq(non_oda_3rdp_project)
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
