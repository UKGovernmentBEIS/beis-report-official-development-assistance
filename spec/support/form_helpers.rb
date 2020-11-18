module FormHelpers
  include ActivityHelper
  def fill_in_activity_form(
    delivery_partner_identifier: "A-Unique-Identifier",
    roda_identifier_fragment: "RODA-ID",
    title: "My Aid Activity",
    description: Faker::Lorem.paragraph,
    objectives: Faker::Lorem.paragraph,
    sector_category: "Basic Education",
    sector: "Primary education",
    call_present: "true",
    call_open_date_day: "1",
    call_open_date_month: "10",
    call_open_date_year: "2019",
    call_close_date_day: "31",
    call_close_date_month: "12",
    call_close_date_year: "2019",
    total_applications: "12",
    total_awards: "5",
    programme_status: "07",
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
    flow: "ODA",
    sdg_1: 1,
    aid_type: "B02",
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
    oda_eligibility: "Eligible",
    oda_eligibility_lead: Faker::Name.name,
    level:,
    parent: nil
  )

    expect(page).to have_content t("form.legend.activity.level")
    expect(page).to have_content t("form.hint.activity.level")
    expect(page).to have_content t("form.hint.activity.level_step.#{level}")
    choose custom_capitalisation(t("page_content.activity.level.#{level}"))
    click_button t("form.button.activity.submit")

    if parent.present?
      expect(page).to have_content t("form.legend.activity.parent", parent_level: t("page_content.activity.level.#{level}", level: parent.level), level: t("page_content.activity.level.#{level}"))
      expect(page).to have_content t("form.hint.activity.parent", parent_level: t("page_content.activity.level.#{parent.level}"), level: t("page_content.activity.level.#{level}"))
      choose parent.title
      click_button t("form.button.activity.submit")
    end

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

    unless level == "fund"
      expect(page).to have_content t("form.label.activity.collaboration_type")
      choose "Bilateral"
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.label.activity.flow")
    expect(page.html).to include t("form.hint.activity.flow")
    select flow, from: "activity[flow]"
    click_button t("form.button.activity.submit")

    unless level == "fund"
      expect(page).to have_content t("form.legend.activity.sdgs_apply")
      expect(page).to have_content t("form.hint.activity.sdgs_apply")
      choose t("form.label.activity.sdgs_apply_options.true")
      select t("form.label.activity.sdg_options.5"), from: "activity[sdg_1]"
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.aid_type")
    expect(page).to have_content t("form.hint.activity.aid_type")
    choose("activity[aid_type]", option: aid_type)
    click_button t("form.button.activity.submit")

    expect(page).to have_content t("form.legend.activity.fstc_applies")
    expect(page.body).to include t("form.hint.activity.fstc_applies", aid_type: aid_type)
    choose("activity[fstc_applies]", option: fstc_applies)
    click_button t("form.button.activity.submit")

    if level == "project" || level == "third_party_project"
      expect(page).to have_content t("page_title.activity_form.show.policy_markers")
      expect(page).to have_content t("form.hint.activity.policy_markers.title")
      expect(page).to have_content("Explanation of responses")
      expect(page).to have_content t("form.legend.activity.policy_markers.responses.not_assessed")
      expect(page).to have_content t("form.hint.activity.policy_markers.responses.not_assessed")

      expect(page).to have_content t("form.legend.activity.policy_markers.gender")
      select policy_marker_gender, from: "activity[policy_marker_gender]"

      expect(page).to have_content t("form.legend.activity.policy_markers.climate_change_adaptation")
      select policy_marker_climate_change_adaptation, from: "activity[policy_marker_climate_change_adaptation]"

      expect(page).to have_content t("form.legend.activity.policy_markers.climate_change_mitigation")
      select policy_marker_climate_change_mitigation, from: "activity[policy_marker_climate_change_mitigation]"

      expect(page).to have_content t("form.legend.activity.policy_markers.biodiversity")
      select policy_marker_biodiversity, from: "activity[policy_marker_biodiversity]"

      expect(page).to have_content t("form.legend.activity.policy_markers.desertification")
      select policy_marker_desertification, from: "activity[policy_marker_desertification]"

      expect(page).to have_content t("form.legend.activity.policy_markers.disability")
      select policy_marker_disability, from: "activity[policy_marker_disability]"

      expect(page).to have_content t("form.legend.activity.policy_markers.disaster_risk_reduction")
      select policy_marker_disaster_risk_reduction, from: "activity[policy_marker_disaster_risk_reduction]"

      expect(page).to have_content t("form.legend.activity.policy_markers.nutrition")
      select policy_marker_nutrition, from: "activity[policy_marker_nutrition]"
      click_button t("form.button.activity.submit")
    end

    expect(page).to have_content t("form.legend.activity.covid19_related")
    choose("activity[covid19_related]", option: covid19_related)
    click_button t("form.button.activity.submit")

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
    expect(page).to have_content recipient_region
    expect(page).to have_content intended_beneficiaries
    expect(page).to have_content gdi
    expect(page).to have_content flow
    expect(page).to have_content t("activity.aid_type.#{aid_type.downcase}")
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
    expect(page).to have_content oda_eligibility
    expect(page).to have_content oda_eligibility_lead if level == "project" || level == "third_party_project"
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

    my_activity = Activity.find_by(delivery_partner_identifier: delivery_partner_identifier)
    iati_status = ProgrammeToIatiStatus.new.programme_status_to_iati_status(programme_status)
    expect(my_activity.status).not_to be_nil
    expect(my_activity.status).to eq(iati_status)
  end

  def fill_in_transaction_form(expectations: true,
    description: "This money will be purchasing a new school roof",
    transaction_type: "Outgoing Pledge",
    date_year: "2020",
    date_month: "1",
    date_day: "2",
    value: "1000.01",
    disbursement_channel: "Money is disbursed through central Ministry of Finance or Treasury",
    currency: "Pound Sterling",
    providing_organisation: OpenStruct.new(name: "Example provider", reference: "GB-GOV-1", type: "Government"),
    receiving_organisation: OpenStruct.new(name: "Example receiver", reference: "GB-COH-123", type: "Private Sector"))
    fill_in "transaction[description]", with: description
    select transaction_type, from: "transaction[transaction_type]"
    fill_in "transaction[date(3i)]", with: date_day
    fill_in "transaction[date(2i)]", with: date_month
    fill_in "transaction[date(1i)]", with: date_year
    fill_in "transaction[value]", with: value
    select disbursement_channel, from: "transaction[disbursement_channel]"
    select currency, from: "transaction[currency]"

    fill_in "transaction[providing_organisation_name]", with: providing_organisation.name
    select providing_organisation.type, from: "transaction[providing_organisation_type]"
    fill_in "transaction[providing_organisation_reference]", with: providing_organisation.reference

    fill_in "transaction[receiving_organisation_name]", with: receiving_organisation.name
    select receiving_organisation.type, from: "transaction[receiving_organisation_type]"
    fill_in "transaction[receiving_organisation_reference]", with: receiving_organisation.reference

    click_on(t("default.button.submit"))

    if expectations
      within ".transactions" do
        expect(page).to have_content(transaction_type)
        expect(page).to have_content localise_date_from_input_fields(
          year: date_year,
          month: date_month,
          day: date_day
        )
        expect(page).to have_content(ActionController::Base.helpers.number_to_currency(value, unit: "£"))
        expect(page).to have_content(disbursement_channel)
        expect(page).to have_content(currency)
        expect(page).to have_content(providing_organisation.name)
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

  private def activity_level(level)
    t("page_content.activity.level.#{level}")
  end
end
