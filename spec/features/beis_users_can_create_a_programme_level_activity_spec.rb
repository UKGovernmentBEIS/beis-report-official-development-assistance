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
