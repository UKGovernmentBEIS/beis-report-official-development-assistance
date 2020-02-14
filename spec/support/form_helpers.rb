module FormHelpers
  def fill_in_activity_form(
    identifier: "A-Unique-Identifier",
    title: "My Aid Activity",
    description: Faker::Lorem.paragraph,
    sector: "Education policy and administrative management",
    status: "Implementation",
    planned_start_date_day: "1",
    planned_start_date_month: "1",
    planned_start_date_year: "2020",
    planned_end_date_day: "1",
    planned_end_date_month: "1",
    planned_end_date_year: "2021",
    actual_start_date_day: "2",
    actual_start_date_month: "2",
    actual_start_date_year: "2022",
    actual_end_date_day: "2",
    actual_end_date_month: "2",
    actual_end_date_year: "2023",
    recipient_region: "Developing countries, unspecified",
    flow: "ODA",
    finance: "Standard grant",
    aid_type: "General budget support",
    tied_status: "Untied"
  )

    expect(page).to have_content I18n.t("page_title.activity_form.show.identifier")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.identifier")
    expect(page).to have_content I18n.t("helpers.hint.activity.identifier")
    fill_in "activity[identifier]", with: identifier
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.title")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.description")
    fill_in "activity[title]", with: title
    fill_in "activity[description]", with: description
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.sector")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.sector")
    expect(page).to have_content "Classify the purpose of this activity. Please provide the sector appropriate to you from this list."
    select sector, from: "activity[sector]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.status")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.status")
    expect(page).to have_content "IATI activity status. See IATI for detailed descriptions."

    select status, from: "activity[status]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.dates")

    expect(page).to have_content I18n.t("helpers.fieldset.activity.planned_start_date")
    fill_in "activity[planned_start_date(3i)]", with: planned_start_date_day
    fill_in "activity[planned_start_date(2i)]", with: planned_start_date_month
    fill_in "activity[planned_start_date(1i)]", with: planned_start_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.activity.planned_end_date")
    fill_in "activity[planned_end_date(3i)]", with: planned_end_date_day
    fill_in "activity[planned_end_date(2i)]", with: planned_end_date_month
    fill_in "activity[planned_end_date(1i)]", with: planned_end_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.activity.actual_start_date")
    fill_in "activity[actual_start_date(3i)]", with: actual_start_date_day
    fill_in "activity[actual_start_date(2i)]", with: actual_start_date_month
    fill_in "activity[actual_start_date(1i)]", with: actual_start_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.activity.actual_end_date")
    fill_in "activity[actual_end_date(3i)]", with: actual_end_date_day
    fill_in "activity[actual_end_date(2i)]", with: actual_end_date_month
    fill_in "activity[actual_end_date(1i)]", with: actual_end_date_year

    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.country")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.recipient_region")
    expect(page).to have_content "A supranational geopolitical region that will benefit from this activity. Find the region code from the IATI region list."
    select recipient_region, from: "activity[recipient_region]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.flow")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.flow")
    expect(page).to have_content "IATI descriptions of each flow type can be found here."
    select flow, from: "activity[flow]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.finance")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.finance")
    expect(page).to have_content I18n.t("helpers.hint.activity.finance")
    select finance, from: "activity[finance]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.aid_type")
    expect(page).to have_content "A code for the vocabulary aid-type classifications. IATI descriptions can be found here."
    select aid_type, from: "activity[aid_type]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")
    expect(page).to have_content I18n.t("activerecord.attributes.activity.tied_status")
    expect(page).to have_content "See the IATI tied status page for descriptions."

    select tied_status, from: "activity[tied_status]"

    click_button I18n.t("form.activity.submit")

    expect(page).to have_content identifier
    expect(page).to have_content title
    expect(page).to have_content description
    expect(page).to have_content sector
    expect(page).to have_content status
    expect(page).to have_content recipient_region
    expect(page).to have_content flow
    expect(page).to have_content finance
    expect(page).to have_content aid_type
    expect(page).to have_content tied_status
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
  end

  def fill_in_transaction_form(expectations: true,
    reference: "123",
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
    fill_in "transaction[reference]", with: reference
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

    click_on(I18n.t("generic.button.submit"))

    if expectations
      within ".transactions" do
        expect(page).to have_content(reference)
        expect(page).to have_content(description)
        expect(page).to have_content(transaction_type)
        expect(page).to have_content localise_date_from_input_fields(
          year: date_year,
          month: date_month,
          day: date_day
        )
        expect(page).to have_content(value)
        expect(page).to have_content(disbursement_channel)
        expect(page).to have_content(currency)
        expect(page).to have_content(providing_organisation.name)
        expect(page).to have_content(receiving_organisation.name)
      end
    end
  end

  def localise_date_from_input_fields(year:, month:, day:)
    I18n.l(Date.parse("#{year}-#{month}-#{day}"))
  end
end
