RSpec.feature "Users can create a project" do
  context "when they are a delivery partner" do
    let(:user) { create(:partner_organisation_user) }
    before { authenticate!(user: user) }
    after { logout }

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

        activity = build(:project_activity, :newton_funded, :with_commitment,
          country_partner_organisations: ["National Council for the State Funding Agencies (CONFAP)"],
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
        expect(created_activity.country_partner_organisations).to eq(activity.country_partner_organisations)
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
        expect(created_activity.uk_po_named_contact).to eq(activity.uk_po_named_contact)
        expect(created_activity.implementing_organisations).to be_none
        expect(created_activity.commitment.value).to eq(activity.commitment.value)

        expect(created_activity.publish_to_iati).to be(true)
      end

      scenario "a new project can be added to an ISPF ODA programme" do
        programme = create(:programme_activity, :ispf_funded, extending_organisation: user.organisation)
        report = create(:report, :active, :for_ispf, is_oda: programme.is_oda, organisation: user.organisation)
        activity = build(:project_activity,
          :with_commitment,
          parent: programme,
          is_oda: true,
          ispf_oda_partner_countries: ["IN"],
          ispf_non_oda_partner_countries: ["IN"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,
          ispf_themes: [1],
          tags: [1])

        visit activities_path
        click_on programme.title
        click_on t("tabs.activity.children")
        click_on t("action.activity.add_child")

        form = ActivityForm.new(activity: activity, level: "project", fund: "ispf")
        form.complete!

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(programme.child_activities.last)

        # our new direct association between activity and report
        expect(created_activity.originating_report).to eq(report)
        expect(report.new_activities).to eq([created_activity])

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
        expect(created_activity.ispf_oda_partner_countries).to match_array(activity.ispf_oda_partner_countries)
        expect(created_activity.ispf_non_oda_partner_countries).to match_array(activity.ispf_non_oda_partner_countries)
        expect(created_activity.benefitting_countries).to match_array(activity.benefitting_countries)
        expect(created_activity.gdi).to eq(activity.gdi)
        expect(created_activity.aid_type).to eq(activity.aid_type)
        expect(created_activity.collaboration_type).to eq(activity.collaboration_type)
        expect(created_activity.sdgs_apply).to eq(activity.sdgs_apply)
        expect(created_activity.sdg_1).to eq(activity.sdg_1)
        expect(created_activity.ispf_themes).to eq(activity.ispf_themes)
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
        expect(created_activity.implementing_organisations).to be_none
        expect(created_activity.tags).to eq(activity.tags)
        expect(created_activity.commitment.value).to eq(activity.commitment.value)

        expect(created_activity.publish_to_iati).to be(true)
      end

      scenario "a new project can be added to an ISPF non-ODA programme" do
        programme = create(:programme_activity, :ispf_funded, extending_organisation: user.organisation, is_oda: false)
        report = create(:report, :active, :for_ispf, is_oda: programme.is_oda, organisation: user.organisation)
        activity = build(:project_activity,
          :with_commitment,
          parent: programme,
          is_oda: false,
          ispf_non_oda_partner_countries: ["IN"],
          benefitting_countries: ["AG", "HT"],
          sdgs_apply: true,
          sdg_1: 5,
          ispf_themes: [1],
          tags: [1, 3])

        visit activities_path
        click_on programme.title
        click_on t("tabs.activity.children")
        click_on t("action.activity.add_child")

        form = ActivityForm.new(activity: activity, level: "project", fund: "ispf")
        form.complete!

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        created_activity = form.created_activity

        expect(created_activity).to eq(programme.child_activities.last)

        # our new direct association between activity and report
        expect(created_activity.originating_report).to eq(report)
        expect(report.new_activities).to eq([created_activity])

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
        expect(created_activity.ispf_non_oda_partner_countries).to match_array(activity.ispf_non_oda_partner_countries)
        expect(created_activity.ispf_themes).to eq(activity.ispf_themes)
        expect(created_activity.uk_po_named_contact).to eq(activity.uk_po_named_contact)
        expect(created_activity.implementing_organisations).to be_none
        expect(created_activity.tags).to eq(activity.tags)
        expect(created_activity.finance).to be_nil
        expect(created_activity.tied_status).to be_nil
        expect(created_activity.flow).to be_nil
        expect(created_activity.transparency_identifier).to be_nil
        expect(created_activity.oda_eligibility).to be_nil
        expect(created_activity.fstc_applies).to be_nil
        expect(created_activity.covid19_related).to be_nil
        expect(created_activity.policy_marker_gender).to be_nil
        expect(created_activity.policy_marker_climate_change_adaptation).to be_nil
        expect(created_activity.policy_marker_climate_change_mitigation).to be_nil
        expect(created_activity.policy_marker_biodiversity).to be_nil
        expect(created_activity.policy_marker_desertification).to be_nil
        expect(created_activity.policy_marker_disability).to be_nil
        expect(created_activity.policy_marker_disaster_risk_reduction).to be_nil
        expect(created_activity.policy_marker_nutrition).to be_nil
        expect(created_activity.commitment.value).to eq(activity.commitment.value)

        expect(created_activity.publish_to_iati).to be(false)
      end

      context "when the `activity_linking` feature flag is enabled" do
        before do
          allow(ROLLOUT).to receive(:active?).and_call_original
          allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true)
        end

        scenario "a non-ODA project can be linked to an existing ODA project" do
          oda_programme = create(:programme_activity, :ispf_funded,
            is_oda: true,
            extending_organisation: user.organisation)
          oda_project = create(:project_activity, :ispf_funded, :with_report,
            parent: oda_programme,
            is_oda: true,
            ispf_themes: [1],
            extending_organisation: user.organisation)
          non_oda_programme = create(:programme_activity, :ispf_funded,
            is_oda: false,
            linked_activity: oda_programme,
            extending_organisation: user.organisation)
          _report = create(:report, :for_ispf, is_oda: false, organisation: user.organisation)
          non_oda_project = build(:project_activity, :ispf_funded, :with_commitment,
            parent: non_oda_programme,
            is_oda: false,
            linked_activity_id: oda_project.id,
            ispf_themes: [1],
            extending_organisation: user.organisation)

          visit activities_path
          click_on non_oda_programme.title
          click_on t("tabs.activity.children")
          click_on t("action.activity.add_child")

          form = ActivityForm.new(activity: non_oda_project, level: "project", fund: "ispf")
          form.complete!

          expect(page).to have_content(t("action.project.create.success"))

          created_activity = form.created_activity

          expect(created_activity.title).to eq(non_oda_project.title)
          expect(created_activity.is_oda).to eq(non_oda_project.is_oda)
          expect(created_activity.linked_activity).to eq(oda_project)
        end
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

        expect(page).to have_content t("page_title.activity_form.show.purpose", level: "project (level C)")
      end
    end
  end
end
