module FormHelpers
  include ActivityHelper
  def fill_in_activity_form(
    level:,
    delivery_partner_identifier: "A-Unique-Identifier",
    roda_identifier_fragment: "RODA-ID",
    title: "My Aid Activity",
    description: Faker::Lorem.paragraph,
    objectives: Faker::Lorem.paragraph,
    sector_category: "Basic Education",
    sector: "Primary education (11220)",
    call_present: "true",
    call_open_date_day: "1",
    call_open_date_month: "10",
    call_open_date_year: "2019",
    call_close_date_day: "31",
    call_close_date_month: "12",
    call_close_date_year: "2019",
    total_applications: "12",
    total_awards: "5",
    programme_status: "spend_in_progress",
    country_delivery_partners: "National Council for the State Funding Agencies (CONFAP)",
    planned_start_date_day: "1",
    planned_start_date_month: "1",
    planned_start_date_year: "2020",
    planned_end_date_day: "1",
    planned_end_date_month: "1",
    planned_end_date_year: "2021",
    actual_start_date_day: "1",
    actual_start_date_month: "1",
    actual_start_date_year: "2020",
    actual_end_date_day: "1",
    actual_end_date_month: "2",
    actual_end_date_year: "2020",
    geography: "recipient_region",
    recipient_region: "Developing countries, unspecified",
    intended_beneficiaries: "Haiti",
    gdi: "GDI not applicable",
    collaboration_type: "Bilateral",
    sdg_1: 1,
    fund_pillar: "1",
    aid_type: "D01",
    fstc_applies: true,
    policy_marker_gender: "Not assessed",
    policy_marker_climate_change_adaptation: "Not targeted",
    policy_marker_climate_change_mitigation: "Significant objective",
    policy_marker_biodiversity: "Principal objective",
    policy_marker_desertification: "Principal objective AND in support of an action programme",
    policy_marker_disability: "Not assessed",
    policy_marker_disaster_risk_reduction: "Not assessed",
    policy_marker_nutrition: "Not assessed",
    covid19_related: "4",
    gcrf_strategic_area: "Academies Collective Fund",
    gcrf_challenge_area: "1",
    oda_eligibility: "Eligible",
    oda_eligibility_lead: Faker::Name.name,
    channel_of_delivery_code: "11000",
    parent: nil,
    uk_dp_named_contact: Faker::Name.name
  )

    expect(page).to have_content t("form.label.activity.delivery_partner_identifier")
    expect(page).to have_content t("form.hint.activity.delivery_partner_identifier")
    fill_in "activity[delivery_partner_identifier]", with: delivery_partner_identifier
    click_button t("form.button.activity.submit")

    if parent.blank? || parent.roda_identifier_fragment.present?
      expect(page).to have_content t("form.label.activity.roda_identifier_fragment")
      expect(page).to have_content t("form.hint.activity.roda_identifier_fragment")
      fill_in "activity[roda_identifier_fragment]", with: roda_identifier_fragment
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.purpose", level: activity_level(level))
    expect(page).to have_content custom_capitalisation(t("form.label.activity.title", level: activity_level(level)))
    expect(page).to have_content t("form.label.activity.description")
    fill_in "activity[title]", with: title
    fill_in "activity[description]", with: description
    click_button t("form.button.activity.submit")

    unless level == "fund"
      expect(page).to have_content t("form.legend.activity.objectives", level: activity_level(level))
      expect(page).to have_content t("form.hint.activity.objectives")
      fill_in "activity[objectives]", with: objectives
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.sector_category", level: activity_level(level))
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize(
        t("form.legend.activity.sector_category", level: t("page_content.activity.level.#{level}"))
      )
    )
    choose sector_category
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.legend.activity.sector", sector_category: sector_category, level: activity_level(level))

    choose sector
    click_button t("form.button.activity.submit")

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("form.legend.activity.call_present", level: activity_level(level))
      choose "Yes"
      click_button t("form.button.activity.submit")
      expect(page).to have_content t("page_title.activity_form.show.call_dates", level: activity_level(level))

      expect(page).to have_content t("form.legend.activity.call_open_date")
      fill_in "activity[call_open_date(3i)]", with: call_open_date_day
      fill_in "activity[call_open_date(2i)]", with: call_open_date_month
      fill_in "activity[call_open_date(1i)]", with: call_open_date_year

      expect(page).to have_content t("form.legend.activity.call_close_date")
      fill_in "activity[call_close_date(3i)]", with: call_close_date_day
      fill_in "activity[call_close_date(2i)]", with: call_close_date_month
      fill_in "activity[call_close_date(1i)]", with: call_close_date_year

      click_button t("form.button.activity.submit")
    else
      call_present = nil
    end

    if call_present == "true"
      expect(page).to have_content t("form.legend.activity.total_applications")
      expect(page).to have_content t("form.hint.activity.total_applications")
      fill_in "activity[total_applications]", with: total_applications

      expect(page).to have_content t("form.legend.activity.total_awards")
      expect(page).to have_content t("form.hint.activity.total_awards")
      fill_in "activity[total_awards]", with: total_awards

      click_button t("form.button.activity.submit")
    end

    unless level == "fund"
      expect(page).to have_content t("form.legend.activity.programme_status")
      expect(page).to have_content "Delivery"
      expect(page).to have_content "Planned"
      expect(page).to have_content "Agreement in place"
      expect(page).to have_content "Call/Activity open"
      expect(page).to have_content "Review"
      expect(page).to have_content "Decided"
      expect(page).to have_content "Spend in progress"
      expect(page).to have_content "Finalisation"
      expect(page).to have_content "Completed"
      expect(page).to have_content "Stopped"
      expect(page).to have_content "Cancelled"

      choose("activity[programme_status]", option: programme_status)
      click_button t("form.button.activity.submit")
    end

    # NB: Since the parent might be a fund, `is_newton_fund?` won't work here
    if parent&.associated_fund&.roda_identifier_fragment == "NF"
      expect(page).to have_content t("form.legend.activity.country_delivery_partners")
      expect(page).to have_content t("form.hint.activity.country_delivery_partners")
      fill_in "activity[country_delivery_partners][]", match: :first, with: country_delivery_partners

      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("page_title.activity_form.show.dates", level: activity_level(level))

    expect(page).to have_content t("form.legend.activity.planned_start_date")
    fill_in "activity[planned_start_date(3i)]", with: planned_start_date_day
    fill_in "activity[planned_start_date(2i)]", with: planned_start_date_month
    fill_in "activity[planned_start_date(1i)]", with: planned_start_date_year

    expect(page).to have_content t("form.legend.activity.planned_end_date")
    fill_in "activity[planned_end_date(3i)]", with: planned_end_date_day
    fill_in "activity[planned_end_date(2i)]", with: planned_end_date_month
    fill_in "activity[planned_end_date(1i)]", with: planned_end_date_year

    expect(page).to have_content t("form.legend.activity.actual_start_date")
    fill_in "activity[actual_start_date(3i)]", with: actual_start_date_day
    fill_in "activity[actual_start_date(2i)]", with: actual_start_date_month
    fill_in "activity[actual_start_date(1i)]", with: actual_start_date_year

    expect(page).to have_content t("form.legend.activity.actual_end_date")
    fill_in "activity[actual_end_date(3i)]", with: actual_end_date_day
    fill_in "activity[actual_end_date(2i)]", with: actual_end_date_month
    fill_in "activity[actual_end_date(1i)]", with: actual_end_date_year

    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.legend.activity.geography")
    choose "Region"
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.label.activity.recipient_region")
    select recipient_region, from: "activity[recipient_region]"
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
    choose "Yes"
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.label.activity.intended_beneficiaries")
    check intended_beneficiaries
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.label.activity.gdi")
    expect(page).to have_content t("form.hint.activity.gdi")
    choose "GDI not applicable"
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.legend.activity.aid_type")
    expect(page).to have_content t("form.hint.activity.aid_type")
    choose("activity[aid_type]", option: aid_type)
    click_button t("form.button.activity.submit")

    unless level == "fund"
      expect(page).to have_content t("form.label.activity.collaboration_type")
      choose "Bilateral"
      click_button t("form.button.activity.submit")
    end

    unless level == "fund"
      expect(page).to have_content t("form.legend.activity.sdgs_apply")
      expect(page).to have_content t("form.hint.activity.sdgs_apply")
      choose t("form.label.activity.sdgs_apply_options.true")
      select t("form.label.activity.sdg_options.5"), from: "activity[sdg_1]"
      click_button t("form.button.activity.submit")
    end

    if associated_fund_is_newton?(parent)
      expect(page).to have_content t("form.legend.activity.fund_pillar")
      expect(page).to have_content t("form.hint.activity.fund_pillar")

      choose("activity[fund_pillar]", option: fund_pillar)
      click_button t("form.button.activity.submit")
    end

    if aid_type.in?(["C01", "B03"])
      expect(page).to have_content t("form.legend.activity.fstc_applies")
      expect(page.body).to include t("form.hint.activity.fstc_applies")
      choose("activity[fstc_applies]", option: fstc_applies ? "1" : "0")
      click_button t("form.button.activity.submit")
    end

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("page_title.activity_form.show.policy_markers")
      expect(page).to have_content t("form.hint.activity.policy_markers.title")
      expect(page).to have_content t("form.legend.activity.policy_markers.responses.not_assessed")
      expect(page).to have_content t("form.hint.activity.policy_markers.responses.not_assessed")

      expect(page).to have_content t("form.legend.activity.policy_marker_gender")
      choose(policy_marker_gender, name: "activity[policy_marker_gender]")

      expect(page).to have_content t("form.legend.activity.policy_marker_climate_change_adaptation")
      choose(policy_marker_climate_change_adaptation, name: "activity[policy_marker_climate_change_adaptation]")

      expect(page).to have_content t("form.legend.activity.policy_marker_climate_change_mitigation")
      choose(policy_marker_climate_change_mitigation, name: "activity[policy_marker_climate_change_mitigation]")

      expect(page).to have_content t("form.legend.activity.policy_marker_biodiversity")
      choose(policy_marker_biodiversity, name: "activity[policy_marker_biodiversity]")

      expect(page).to have_content t("form.legend.activity.policy_marker_desertification")
      choose(policy_marker_desertification, name: "activity[policy_marker_desertification]")

      expect(page).to have_content t("form.legend.activity.policy_marker_disability")
      choose(policy_marker_disability, name: "activity[policy_marker_disability]")

      expect(page).to have_content t("form.legend.activity.policy_marker_disaster_risk_reduction")
      choose(policy_marker_disaster_risk_reduction, name: "activity[policy_marker_disaster_risk_reduction]")

      expect(page).to have_content t("form.legend.activity.policy_marker_nutrition")
      choose(policy_marker_nutrition, name: "activity[policy_marker_nutrition]")

      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.covid19_related")
    choose("activity[covid19_related]", option: covid19_related)
    click_button t("form.button.activity.submit")

    if parent&.is_gcrf_funded? || parent&.roda_identifier_fragment == "GCRF"
      expect(page).to have_content t("form.legend.activity.gcrf_strategic_area")
      expect(page).to have_content t("form.hint.activity.gcrf_strategic_area")
      check gcrf_strategic_area
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.legend.activity.gcrf_challenge_area")
      expect(page).to have_content t("form.hint.activity.gcrf_challenge_area")
      choose("activity[gcrf_challenge_area]", option: gcrf_challenge_area)
      click_button t("form.button.activity.submit")
    end

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("form.legend.activity.channel_of_delivery_code")
      choose("activity[channel_of_delivery_code]", option: channel_of_delivery_code)
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.oda_eligibility")
    expect(page).to have_content t("form.hint.activity.oda_eligibility")
    choose oda_eligibility
    click_button t("form.button.activity.submit")

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("form.label.activity.oda_eligibility_lead")
      expect(page).to have_content t("form.hint.activity.oda_eligibility_lead")
      fill_in "activity[oda_eligibility_lead]", with: oda_eligibility_lead
      click_button t("form.button.activity.submit")
    end

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("form.label.activity.uk_dp_named_contact")
      fill_in "activity[uk_dp_named_contact]", with: uk_dp_named_contact
      click_button t("form.button.activity.submit")
    end

    # Activity details page ===================================================
    expect(page).to have_content delivery_partner_identifier
    expect(page).to have_content title
    expect(page).to have_content description
    expect(page).to have_content sector
    if call_present == "true"
      expect(page).to have_content t("activity.call_present.#{call_present}")
      expect(page).to have_content total_applications
      expect(page).to have_content total_awards
    end

    if level == "fund"
      expect(page).not_to have_content t("activity.programme_status.#{programme_status}")
      expect(page).not_to have_content objectives
    else
      expect(page).to have_content t("activity.programme_status.#{programme_status}")
      expect(page).to have_content collaboration_type
      expect(page).to have_content objectives
    end

    # NB: Since the parent might be a fund, `is_newton_fund?` won't work here
    if parent&.associated_fund&.roda_identifier_fragment == "NF"
      expect(page).to have_css(".govuk-summary-list__row.country_delivery_partners")
      expect(page).to have_content country_delivery_partners if country_delivery_partners.present?
    else
      expect(page).to have_no_css(".govuk-summary-list__row.country_delivery_partners")
    end

    expect(page).to have_content recipient_region
    expect(page).to have_content intended_beneficiaries
    expect(page).to have_content gdi
    expect(page).to have_content t("activity.aid_type.#{aid_type.downcase}")

    within(".govuk-summary-list__row.fstc_applies") do
      if aid_type.in?(["B03", "C01"])
        expect(page).to have_content t("summary.label.activity.fstc_applies.#{fstc_applies}")
      elsif aid_type.in?(["D01", "D02", "E01", "E02"])
        expect(page).to have_content "Yes"
      elsif aid_type.in?(["G01", "B02"])
        expect(page).to have_content "No"
      end
    end

    if level == "project" || level == "third_party_project"
      within(".policy_marker_gender") do
        expect(page).to have_content policy_marker_gender
      end
      within(".policy_marker_climate_change_adaptation") do
        expect(page).to have_content policy_marker_climate_change_adaptation
      end
      within(".policy_marker_climate_change_mitigation") do
        expect(page).to have_content policy_marker_climate_change_mitigation
      end
      within(".policy_marker_biodiversity") do
        expect(page).to have_content policy_marker_biodiversity
      end
      within(".policy_marker_desertification") do
        expect(page).to have_content policy_marker_desertification
      end
      within(".policy_marker_disability") do
        expect(page).to have_content policy_marker_disability
      end
      within(".policy_marker_disaster_risk_reduction") do
        expect(page).to have_content policy_marker_disaster_risk_reduction
      end
      within(".policy_marker_nutrition") do
        expect(page).to have_content policy_marker_nutrition
      end
    end
    expect(page).to have_content fund_pillar if associated_fund_is_newton?(parent)

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("summary.label.activity.channel_of_delivery_code")
      expect(page).to have_content channel_of_delivery_code
    end

    expect(page).to have_content oda_eligibility
    expect(page).to have_content oda_eligibility_lead if level == "project" || level == "third_party_project"
    if level == "project" || level == "third_party_project"
      expect(page).to have_content uk_dp_named_contact
    end
    expect(page).to have_content localise_date_from_input_fields(
      year: planned_start_date_year,
      month: planned_start_date_month,
      day: planned_start_date_day
    )
    expect(page).to have_content localise_date_from_input_fields(
      year: planned_end_date_year,
      month: planned_end_date_month,
      day: planned_end_date_day
    )
    if call_present == "true"
      expect(page).to have_content localise_date_from_input_fields(
        year: call_open_date_year,
        month: call_open_date_month,
        day: call_open_date_day
      )
      expect(page).to have_content localise_date_from_input_fields(
        year: call_close_date_year,
        month: call_close_date_month,
        day: call_close_date_day
      )
    end
  end

  def fill_in_transaction_form(expectations: true,
    value: "1000.01",
    financial_quarter: "4",
    financial_year: "2019-2020",
    receiving_organisation: OpenStruct.new(name: "Example receiver", reference: "GB-COH-123", type: "Private Sector"))

    fill_in "transaction[value]", with: value
    choose financial_quarter, name: "transaction[financial_quarter]"
    select financial_year, from: "transaction[financial_year]"
    fill_in "transaction[receiving_organisation_name]", with: receiving_organisation.name
    select receiving_organisation.type, from: "transaction[receiving_organisation_type]" if receiving_organisation.type.present?
    fill_in "transaction[receiving_organisation_reference]", with: receiving_organisation.reference

    click_on(t("default.button.submit"))

    if expectations
      within ".transactions" do
        start_year = financial_year.split("-").first.to_i
        expect(page).to have_content(FinancialQuarter.new(start_year, financial_quarter).to_s)
        expect(page).to have_content(ActionController::Base.helpers.number_to_currency(value, unit: "£"))
        expect(page).to have_content(receiving_organisation.name)
      end
    end
  end

  def fill_in_planned_disbursement_form(
    financial_quarter: "Q2",
    financial_year: "2020-2021",
    value: "100000"
  )

    choose financial_quarter
    select financial_year, from: "Financial year"

    fill_in "planned_disbursement[value]", with: value

    click_on(t("default.button.submit"))
  end

  def fill_in_planned_disbursement_form_for_activity(activity)
    report = Report.editable_for_activity(activity)
    year = report.financial_year

    fill_in_planned_disbursement_form(
      financial_quarter: "Q#{report.financial_quarter}",
      financial_year: "#{year + 1}-#{year + 2}"
    )
  end

  def localise_date_from_input_fields(year:, month:, day:)
    I18n.l(Date.parse("#{year}-#{month}-#{day}"))
  end

  def fill_in_outgoing_transfer_form(destination: create(:project_activity), financial_quarter: FinancialQuarter.for_date(Date.today).to_i, financial_year: FinancialYear.for_date(Date.today).to_i, value: 1234)
    transfer = build(
      :outgoing_transfer,
      destination: destination,
      financial_quarter: financial_quarter,
      financial_year: financial_year,
      value: value
    )

    fill_in "outgoing_transfer[destination]", with: transfer.destination.roda_identifier
    choose transfer.financial_quarter.to_s, name: "outgoing_transfer[financial_quarter]"
    select transfer.financial_year, from: "outgoing_transfer[financial_year]"
    fill_in "outgoing_transfer[value]", with: transfer.value

    transfer
  end

  def fill_in_matched_effort_form(template = build(:matched_effort))
    select template.organisation.name, from: "matched_effort[organisation_id]"

    page.find(:xpath, "//input[@value='#{template.funding_type}']").set(true)
    page.find(:xpath, "//input[@value='#{template.category}']").set(true)

    fill_in "matched_effort[committed_amount]", with: template.committed_amount

    within "#matched-effort-currency-field" do
      find("option[value='#{template.currency}']").select_option
    end

    fill_in "matched_effort[exchange_rate]", with: template.exchange_rate
    fill_in "matched_effort[date_of_exchange_rate(3i)]", with: template.date_of_exchange_rate.day
    fill_in "matched_effort[date_of_exchange_rate(2i)]", with: template.date_of_exchange_rate.month
    fill_in "matched_effort[date_of_exchange_rate(1i)]", with: template.date_of_exchange_rate.year
    fill_in "matched_effort[notes]", with: template.notes

    click_on t("default.button.submit")
  end

  def fill_in_external_income_form(template = build(:external_income))
    page.find(:xpath, "//input[@value='#{template.financial_quarter}']").set(true)
    select template.financial_year, from: "external_income[financial_year]"
    select template.organisation.name, from: "external_income[organisation_id]"
    fill_in "external_income[amount]", with: template.amount
    check "external_income[oda_funding]" if template.oda_funding
    uncheck "external_income[oda_funding]" unless template.oda_funding

    click_on t("default.button.submit")
  end

  private def activity_level(level)
    t("page_content.activity.level.#{level}")
  end
end
