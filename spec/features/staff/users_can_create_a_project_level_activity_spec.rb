RSpec.feature "Users can create a project" do
  context "when they are a delivery parther" do
    let(:user) { create(:partner_organisation_user) }
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
        report = create(:report, :active, organisation: user.organisation, fund: programme.associated_fund)

        activity = build(:project_activity, :newton_funded,
          country_delivery_partners: ["National Council for the State Funding Agencies (CONFAP)"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5)

        visit activities_path
        click_on programme.title
        click_on t("tabs.activity.children")
        click_on t("action.activity.add_child")

        form = ActivityForm.new(activity: activity, level: "project", fund: "newton")
        form.complete!

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(programme.child_activities.last)

        # our new direct association between activity and report
        expect(created_activity.originating_report).to eq(report)
        expect(report.new_activities).to eq([created_activity])

        expect(created_activity.organisation).to eq(user.organisation)
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
        expect(created_activity.covid19_related).to eq(activity.covid19_related)
        expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)
        expect(created_activity.oda_eligibility_lead).to eq(activity.oda_eligibility_lead)
        expect(created_activity.uk_dp_named_contact).to eq(activity.uk_dp_named_contact)
        expect(created_activity.implementing_organisations).to be_none
      end

      scenario "can create a new child activity for a given programme" do
        gcrf = create(:fund_activity, :gcrf)
        programme = create(:programme_activity, parent: gcrf, extending_organisation: user.organisation)
        _report = create(:report, :active, fund: gcrf, organisation: user.organisation)

        visit organisation_activity_path(programme.organisation, programme)

        click_link t("tabs.activity.children")
        click_button t("action.activity.add_child")
        fill_in "activity[partner_organisation_identifier]", with: "foo"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.purpose", level: "project (level C)")
      end
    end
  end
end
