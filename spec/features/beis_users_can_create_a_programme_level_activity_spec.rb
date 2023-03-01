RSpec.feature "BEIS users can create a programme level activity" do
  let(:user) { create(:beis_user) }
  let(:partner_organisation) { create(:partner_organisation) }
  before { authenticate!(user: user) }
  after { logout }

  context "with a new fund and partner organisation" do
    scenario "they see the button to add a new programme (level B activity)" do
      fund = create(:fund_activity, :gcrf)
      partner_organisation = create(:partner_organisation)

      visit organisation_activities_path(partner_organisation)

      expect(page).to have_button(t("form.button.activity.new_child", name: fund.title))
    end
  end

  context "when the source fund is GCRF" do
    let(:identifier) { "a-fund-has-an-accountable-organisation" }
    let!(:activity) do
      build(:programme_activity, :gcrf_funded,
        partner_organisation_identifier: identifier,
        benefitting_countries: ["AG", "HT"],
        sdgs_apply: true,
        sdg_1: 5)
    end

    scenario "an activity can be created" do
      visit organisation_activities_path(partner_organisation)
      click_on t("form.button.activity.new_child", name: activity.associated_fund.title)

      form = ActivityForm.new(activity: activity, level: "programme", fund: "gcrf")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

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
      expect(created_activity.covid19_related).to eq(activity.covid19_related)
      expect(created_activity.gcrf_strategic_area).to eq(activity.gcrf_strategic_area)
      expect(created_activity.gcrf_challenge_area).to eq(activity.gcrf_challenge_area)
      expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)

      expect(created_activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(created_activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(created_activity.accountable_organisation_type).to eq("10")

      expect(created_activity.transparency_identifier).to eql("GB-GOV-13-#{created_activity.roda_identifier}")

      expect_implementing_organisation_to_be_the_partner_organisation(
        activity: created_activity,
        organisation: partner_organisation
      )
    end
  end

  context "when the source fund is Newton" do
    let(:identifier) { "a-fund-has-an-accountable-organisation" }
    let!(:activity) do
      build(:programme_activity, :newton_funded,
        partner_organisation_identifier: identifier,
        benefitting_countries: ["AG", "HT"],
        sdgs_apply: true,
        sdg_1: 5)
    end

    scenario "an activity can be created" do
      visit organisation_activities_path(partner_organisation)
      click_on t("form.button.activity.new_child", name: activity.associated_fund.title)

      form = ActivityForm.new(activity: activity, level: "programme", fund: "newton")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

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
      expect(created_activity.fund_pillar).to eq(activity.fund_pillar)
      expect(created_activity.covid19_related).to eq(activity.covid19_related)
      expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)

      expect(created_activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(created_activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(created_activity.accountable_organisation_type).to eq("10")

      expect(created_activity.transparency_identifier).to eql("GB-GOV-13-#{created_activity.roda_identifier}")
    end
  end

  context "when the source fund is OODA" do
    let(:identifier) { "a-fund-has-an-accountable-organisation" }
    let!(:activity) do
      build(:programme_activity, :ooda_funded,
        partner_organisation_identifier: identifier,
        benefitting_countries: ["AG", "HT"],
        sdgs_apply: true,
        sdg_1: 5)
    end

    scenario "an activity can be created" do
      visit organisation_activities_path(partner_organisation)
      click_on t("form.button.activity.new_child", name: activity.associated_fund.title)

      form = ActivityForm.new(activity: activity, level: "programme", fund: "ooda")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

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
      expect(created_activity.covid19_related).to eq(activity.covid19_related)
      expect(created_activity.oda_eligibility).to eq(activity.oda_eligibility)

      expect(created_activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(created_activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(created_activity.accountable_organisation_type).to eq("10")

      expect(created_activity.transparency_identifier).to eql("GB-GOV-13-#{created_activity.roda_identifier}")
    end
  end

  context "when the source fund is ISPF" do
    let(:identifier) { "a-fund-has-an-accountable-organisation" }
    let!(:oda_activity) do
      build(:programme_activity,
        parent: create(:fund_activity, :ispf),
        partner_organisation_identifier: identifier,
        benefitting_countries: ["AG", "HT"],
        sdgs_apply: true,
        sdg_1: 5,
        is_oda: true,
        ispf_themes: [1, 3],
        ispf_oda_partner_countries: ["BR"],
        ispf_non_oda_partner_countries: ["CA"],
        tags: [1])
    end

    let!(:non_oda_activity) do
      build(:programme_activity,
        parent: create(:fund_activity, :ispf),
        partner_organisation_identifier: identifier,
        benefitting_countries: ["AG", "HT"],
        is_oda: false,
        ispf_themes: [1],
        ispf_non_oda_partner_countries: ["CA"],
        tags: [1, 2])
    end

    scenario "an ODA activity can be created" do
      visit organisation_activities_path(partner_organisation)

      click_on t("form.button.activity.new_child", name: oda_activity.associated_fund.title)

      form = ActivityForm.new(activity: oda_activity, level: "programme", fund: "ispf")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

      expect(created_activity.title).to eq(oda_activity.title)
      expect(created_activity.is_oda).to eq(oda_activity.is_oda)
      expect(created_activity.description).to eq(oda_activity.description)
      expect(created_activity.objectives).to eq(oda_activity.objectives)
      expect(created_activity.sector_category).to eq(oda_activity.sector_category)
      expect(created_activity.sector).to eq(oda_activity.sector)
      expect(created_activity.programme_status).to eq(oda_activity.programme_status)
      expect(created_activity.planned_start_date).to eq(oda_activity.planned_start_date)
      expect(created_activity.planned_end_date).to eq(oda_activity.planned_end_date)
      expect(created_activity.actual_start_date).to eq(oda_activity.actual_start_date)
      expect(created_activity.actual_end_date).to eq(oda_activity.actual_end_date)
      expect(created_activity.ispf_oda_partner_countries).to match_array(oda_activity.ispf_oda_partner_countries)
      expect(created_activity.ispf_non_oda_partner_countries).to match_array(oda_activity.ispf_non_oda_partner_countries)
      expect(created_activity.benefitting_countries).to match_array(oda_activity.benefitting_countries)
      expect(created_activity.gdi).to eq(oda_activity.gdi)
      expect(created_activity.aid_type).to eq(oda_activity.aid_type)
      expect(created_activity.ispf_themes).to eq(oda_activity.ispf_themes)
      expect(created_activity.sdgs_apply).to eq(oda_activity.sdgs_apply)
      expect(created_activity.sdg_1).to eq(oda_activity.sdg_1)
      expect(created_activity.oda_eligibility).to eq(oda_activity.oda_eligibility)
      expect(created_activity.tags).to eq(oda_activity.tags)
    end

    scenario "a non-ODA activity can be created" do
      visit organisation_activities_path(partner_organisation)

      click_on t("form.button.activity.new_child", name: non_oda_activity.associated_fund.title)

      form = ActivityForm.new(activity: non_oda_activity, level: "programme", fund: "ispf")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

      expect(created_activity.title).to eq(non_oda_activity.title)
      expect(created_activity.is_oda).to eq(non_oda_activity.is_oda)
      expect(created_activity.description).to eq(non_oda_activity.description)
      expect(created_activity.sector_category).to eq(non_oda_activity.sector_category)
      expect(created_activity.sector).to eq(non_oda_activity.sector)
      expect(created_activity.programme_status).to eq(non_oda_activity.programme_status)
      expect(created_activity.planned_start_date).to eq(non_oda_activity.planned_start_date)
      expect(created_activity.planned_end_date).to eq(non_oda_activity.planned_end_date)
      expect(created_activity.actual_start_date).to eq(non_oda_activity.actual_start_date)
      expect(created_activity.actual_end_date).to eq(non_oda_activity.actual_end_date)
      expect(created_activity.ispf_non_oda_partner_countries).to match_array(non_oda_activity.ispf_non_oda_partner_countries)
      expect(created_activity.ispf_themes).to eq(non_oda_activity.ispf_themes)
      expect(created_activity.tags).to eq(non_oda_activity.tags)
      expect(created_activity.transparency_identifier).to be_nil
      expect(created_activity.finance).to be_nil
      expect(created_activity.tied_status).to be_nil
      expect(created_activity.flow).to be_nil
    end

    scenario "a new non-ODA programme can be linked to an existing ODA programme" do
      linked_oda_activity = create(:programme_activity, :ispf_funded, is_oda: true, extending_organisation: partner_organisation)
      non_oda_activity.linked_activity = linked_oda_activity

      visit organisation_activities_path(partner_organisation)

      click_on t("form.button.activity.new_child", name: linked_oda_activity.associated_fund.title)

      form = ActivityForm.new(activity: non_oda_activity, level: "programme", fund: "ispf")
      form.complete!

      expect(page).to have_content(t("action.programme.create.success"))

      created_activity = form.created_activity

      expect(created_activity.title).to eq(non_oda_activity.title)
      expect(created_activity.is_oda).to eq(non_oda_activity.is_oda)
      expect(created_activity.linked_activity).to eq(linked_oda_activity)
    end

    context "and the feature flag hiding ISPF is enabled for BEIS users" do
      before do
        mock_feature = double(:feature, groups: [:beis_users])
        allow(ROLLOUT).to receive(:get).and_return(mock_feature)
        allow(ROLLOUT).to receive(:active?).and_return(true)
      end

      scenario "there is no link to create a programme" do
        visit organisation_activities_path(partner_organisation)

        expect(page).to_not have_button t("form.button.activity.new_child", name: oda_activity.associated_fund.title)
      end
    end
  end

  def expect_implementing_organisation_to_be_the_partner_organisation(
    activity:,
    organisation:
  )
    expect(activity.implementing_organisations.first)
      .to have_attributes(
        "name" => organisation.name,
        "iati_reference" => organisation.iati_reference,
        "organisation_type" => organisation.organisation_type
      )
  end
end
