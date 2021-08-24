RSpec.feature "BEIS users can create a programme level activity" do
  let(:user) { create(:beis_user) }
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  before { authenticate!(user: user) }

  context "with a new fund and delivery partner" do
    scenario "they see the button to add a new programme (level B activity)" do
      fund = create(:fund_activity, :gcrf)
      delivery_partner_organisation = create(:delivery_partner_organisation)

      visit organisation_activities_path(delivery_partner_organisation)

      expect(page).to have_button(t("form.button.activity.new_child", name: fund.title))
    end
  end

  context "via a delivery partner's activities page" do
    before do
      create(:fund_activity, :gcrf)
      create(:fund_activity, :newton)
    end

    Activity.fund.each do |fund|
      context "with #{fund.title} as the funding source" do
        scenario "reaches the 'roda_identifier' form step, with a newly created programme-level activity" do
          visit organisation_activities_path(delivery_partner)

          click_on t("form.button.activity.new_child", name: fund.title)

          expect(page).to have_content t("form.label.activity.delivery_partner_identifier")

          programme = Activity.programme.first

          expect(programme.form_state).to eq("identifier")
          expect(programme.parent).to eq(fund)
          expect(programme.source_fund).to eq(fund.source_fund)
        end
      end
    end
  end

  context "validations" do
    scenario "validation errors work as expected" do
      fund = create(:fund_activity, :gcrf)
      identifier = "foo"

      visit organisation_activities_path(delivery_partner)
      click_on t("form.button.activity.new_child", name: fund.title)

      # Don't provide an identifier
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.delivery_partner_identifier.blank")

      fill_in "activity[delivery_partner_identifier]", with: identifier
      click_button t("form.button.activity.submit")

      expect(page).to have_content custom_capitalisation(t("form.legend.activity.purpose", level: "programme (level B)"))
      expect(page).to have_content t("form.hint.activity.title", level: "programme (level B)")

      # Don't provide a title and description
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("activerecord.errors.models.activity.attributes.title.blank")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.description.blank")

      fill_in "activity[title]", with: Faker::Lorem.word
      fill_in "activity[description]", with: Faker::Lorem.paragraph
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.objectives", level: "programme (level B)")

      # Don't provide any objectives

      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.objectives.blank")

      fill_in "activity[objectives]", with: Faker::Lorem.paragraph
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.sector_category", level: "programme (level B)")

      # Don't provide a sector category
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector_category.blank")

      choose "Basic Education"
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.sector", sector_category: "Basic Education", level: "programme (level B)")
      # Don't provide a sector
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector.blank")
      choose "Primary education (11220)"
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("form.legend.activity.programme_status", level: "programme (level B)")

      # Don't provide a programme status
      click_button t("form.button.activity.submit")
      expect(page).to have_content "can't be blank"

      choose("activity[programme_status]", option: "spend_in_progress")
      click_button t("form.button.activity.submit")

      if fund.roda_identifier.include?("NF")
        expect(page).to have_content t("form.legend.activity.country_delivery_partners")

        # Don't provide a country delivery partner
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.country_delivery_partners.blank")

        fill_in "activity[country_delivery_partners][]", match: :first, with: "National Council for the State Funding Agencies (CONFAP)"
        click_button t("form.button.activity.submit")
      end
      expect(page).to have_content t("page_title.activity_form.show.dates", level: "programme (level B)")

      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.dates")

      # Dates cannot contain only a zero
      fill_in "activity[planned_start_date(3i)]", with: 1
      fill_in "activity[planned_start_date(2i)]", with: 0
      fill_in "activity[planned_start_date(1i)]", with: 2010
      fill_in "activity[planned_end_date(3i)]", with: 0
      fill_in "activity[planned_end_date(2i)]", with: 12
      fill_in "activity[planned_end_date(1i)]", with: 2010
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_start_date.invalid")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_end_date.invalid")

      fill_in "activity[planned_start_date(3i)]", with: 1
      fill_in "activity[planned_start_date(2i)]", with: 12
      fill_in "activity[planned_start_date(1i)]", with: 2020
      fill_in "activity[planned_end_date(3i)]", with: 1
      fill_in "activity[planned_end_date(2i)]", with: 12
      fill_in "activity[planned_end_date(1i)]", with: 2020
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.benefitting_countries")
      # Benefitting countries do not have presence validation yet
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.label.activity.gdi")

      # Don't select a GDI
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.gdi.blank")

      choose "GDI not applicable"
      click_button t("form.button.activity.submit")

      # Aid type question
      expect(page).to have_content t("form.legend.activity.aid_type")

      # Don't select an aid type
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.aid_type.blank")

      choose("activity[aid_type]", option: "C01")
      click_button t("form.button.activity.submit")

      # Collaboration type question
      expect(page).to have_content t("form.label.activity.collaboration_type")

      # Collaboration_type has a pre-selected option
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.sdgs_apply")

      # Choose option that SDGs apply, but do not select any SDGs
      choose "activity[sdgs_apply]", option: "true"
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.sdg_1.blank")

      # Now select a primary SDG
      select "Quality Education", from: "activity[sdg_1]"
      click_button t("form.button.activity.submit")

      # FSTC question
      expect(page).to have_content t("form.legend.activity.fstc_applies")

      # Don't choose if fstc applies or not
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.fstc_applies.inclusion")

      choose("activity[fstc_applies]", option: 1)
      click_button t("form.button.activity.submit")

      # Covid19-related has a default and can't be set to blank so we skip
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("form.legend.activity.gcrf_strategic_area")
      expect(page).to have_content t("form.hint.activity.gcrf_strategic_area")

      # Don't select a GCRF strategic area
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.gcrf_strategic_area.blank")

      # Select too many GCRF strategic areas
      check "Resilient Futures"
      check "Coherence and Impact"
      check "International Partnerships"
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.gcrf_strategic_area.too_long")

      # GCRF strategic area (GCRF)
      uncheck "Resilient Futures"
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.gcrf_challenge_area")
      expect(page).to have_content t("form.hint.activity.gcrf_challenge_area")

      # Don't select a GCRF challenge area
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("activerecord.errors.models.activity.attributes.gcrf_challenge_area.blank")

      # GCRF challenge area (GCRF)
      choose("activity[gcrf_challenge_area]", option: "1")
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("form.legend.activity.oda_eligibility")

      # oda_eligibility has the default value already selected
      click_button t("form.button.activity.submit")
      expect(page).to have_content Activity.find_by(delivery_partner_identifier: identifier).title
    end
  end

  scenario "the activity can be created with the appropriate defaults" do
    fund = create(:fund_activity, :newton)
    identifier = "a-fund-has-an-accountable-organisation"

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: fund.title)

    fill_in_activity_form(delivery_partner_identifier: identifier, level: "programme", parent: fund)

    activity = Activity.find_by(delivery_partner_identifier: identifier)

    expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
    expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
    expect(activity.accountable_organisation_type).to eq("10")

    expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.roda_identifier}")
  end

  scenario "country_delivery_parters is included in Newton funded programmes" do
    newton_fund = create(:fund_activity, :newton, organisation: user.organisation)

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: newton_fund.title)

    fill_in_activity_form(level: "programme", parent: newton_fund)

    expect(page).to have_content t("action.programme.create.success")
    activity = Activity.order("created_at ASC").last
    expect(activity.country_delivery_partners).to eql(["National Council for the State Funding Agencies (CONFAP)"])
  end

  scenario "non Newton funded programmes do not include 'country_delivery_partners'" do
    other_fund = create(:fund_activity, :gcrf, organisation: user.organisation)

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: other_fund.title)

    fill_in_activity_form(level: "programme", parent: other_fund)

    expect(page).to have_content t("action.programme.create.success")
    activity = Activity.order("created_at ASC").last
    expect(activity.country_delivery_partners).to be_nil
  end

  scenario "a new programme requires specific fields when it is Newton-funded" do
    newton_fund = create(:fund_activity, :newton)

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: newton_fund.title)

    fill_in_activity_form(level: "programme", parent: newton_fund)
  end
end
