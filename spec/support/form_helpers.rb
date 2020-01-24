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
    expect(page).to have_content I18n.t("helpers.hint.fund.identifier")
    fill_in "fund[identifier]", with: identifier
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")
    fill_in "fund[title]", with: title
    fill_in "fund[description]", with: description
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.sector")
    expect(page).to have_content "Classify the purpose of this activity. Please provide the sector appropriate to you from this list."
    select sector, from: "fund[sector]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.status")
    expect(page).to have_content "IATI activity status. See IATI for detailed descriptions."

    select status, from: "fund[status]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.dates")

    expect(page).to have_content I18n.t("helpers.fieldset.fund.planned_start_date")
    fill_in "fund[planned_start_date(3i)]", with: planned_start_date_day
    fill_in "fund[planned_start_date(2i)]", with: planned_start_date_month
    fill_in "fund[planned_start_date(1i)]", with: planned_start_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.fund.planned_end_date")
    fill_in "fund[planned_end_date(3i)]", with: planned_end_date_day
    fill_in "fund[planned_end_date(2i)]", with: planned_end_date_month
    fill_in "fund[planned_end_date(1i)]", with: planned_end_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.fund.actual_start_date")
    fill_in "fund[actual_start_date(3i)]", with: actual_start_date_day
    fill_in "fund[actual_start_date(2i)]", with: actual_start_date_month
    fill_in "fund[actual_start_date(1i)]", with: actual_start_date_year

    expect(page).to have_content I18n.t("helpers.fieldset.fund.actual_end_date")
    fill_in "fund[actual_end_date(3i)]", with: actual_end_date_day
    fill_in "fund[actual_end_date(2i)]", with: actual_end_date_month
    fill_in "fund[actual_end_date(1i)]", with: actual_end_date_year

    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.country")
    expect(page).to have_content "A supranational geopolitical region that will benefit from this activity. Find the region code from the IATI region list."
    select recipient_region, from: "fund[recipient_region]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.flow")
    expect(page).to have_content "IATI descriptions of each flow type can be found here."
    select flow, from: "fund[flow]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.finance")
    expect(page).to have_content I18n.t("helpers.hint.fund.finance")
    select finance, from: "fund[finance]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")
    expect(page).to have_content "A code for the vocabulary aid-type classifications. IATI descriptions can be found here."
    select aid_type, from: "fund[aid_type]"
    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")
    expect(page).to have_content "See the IATI tied status page for descriptions."

    select tied_status, from: "fund[tied_status]"

    click_button I18n.t("form.fund.submit")

    expect(page).to have_content I18n.t("form.fund.create.success")
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
    expect(page).to have_content I18n.l(
      date(
        year: planned_start_date_year,
        month: planned_start_date_month,
        day: planned_start_date_day
      )
    )
    expect(page).to have_content I18n.l(
      date(
        year: planned_end_date_year,
        month: planned_end_date_month,
        day: planned_end_date_day
      )
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
    provider_organisation: Organisation.first,
    receiver_organisation: Organisation.first)
    fill_in "transaction[reference]", with: reference
    fill_in "transaction[description]", with: description
    select transaction_type, from: "transaction[transaction_type]"
    fill_in "transaction[date(3i)]", with: date_day
    fill_in "transaction[date(2i)]", with: date_month
    fill_in "transaction[date(1i)]", with: date_year
    fill_in "transaction[value]", with: value
    select disbursement_channel, from: "transaction[disbursement_channel]"
    select currency, from: "transaction[currency]"
    select provider_organisation.name, from: "transaction[provider_id]"
    select receiver_organisation.name, from: "transaction[receiver_id]"

    click_on(I18n.t("generic.button.submit"))

    if expectations
      within ".transactions" do
        expect(page).to have_content(reference)
        expect(page).to have_content(description)
        expect(page).to have_content(transaction_type)
        expect(page).to have_content(date(year: date_year, month: date_month, day: date_day))
        expect(page).to have_content(value)
        expect(page).to have_content(disbursement_channel)
        expect(page).to have_content(currency)
        expect(page).to have_content(provider_organisation.name)
        expect(page).to have_content(receiver_organisation.name)
      end
    end
  end

  def date(year:, month:, day:)
    Date.parse("#{year}-#{month}-#{day}")
  end
end
