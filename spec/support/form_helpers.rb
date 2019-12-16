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
    recipient_region: "Developing countries, unspecified",
    flow: "ODA",
    finance: "Standard grant",
    aid_type: "General budget support",
    tied_status: "Untied"
  )
    expect(page).to have_content I18n.t("page_title.activity_form.show.identifier")
    fill_in "activity[identifier]", with: identifier
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")
    fill_in "activity[title]", with: title
    fill_in "activity[description]", with: description
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.sector")
    select sector, from: "activity[sector]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.status")
    select status, from: "activity[status]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.dates")
    fill_in "planned_start_date[day]", with: planned_start_date_day
    fill_in "planned_start_date[month]", with: planned_start_date_month
    fill_in "planned_start_date[year]", with: planned_start_date_year
    fill_in "planned_end_date[day]", with: planned_end_date_day
    fill_in "planned_end_date[month]", with: planned_end_date_month
    fill_in "planned_end_date[year]", with: planned_end_date_year
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.country")
    select recipient_region, from: "activity[recipient_region]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.flow")
    select flow, from: "activity[flow]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.finance")
    select finance, from: "activity[finance]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")
    select aid_type, from: "activity[aid_type]"
    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")
    select tied_status, from: "activity[tied_status]"

    click_button I18n.t("form.activity.submit")

    expect(page).to have_content I18n.t("form.activity.create.success")
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

        # TODO: The table cannot support more horiztonal columns right now.
        # Remove temporary substitute assertion that checks the DB instead.
        # expect(page).to have_content(provider_organisation.name)
        # expect(page).to have_content(receiver_organisation.name)
        expect(Transaction.find_by(reference: reference).provider.name)
          .to eq(provider_organisation.name)
        expect(Transaction.find_by(reference: reference).receiver.name)
          .to eq(receiver_organisation.name)
      end
    end
  end

  def date(year:, month:, day:)
    Date.parse("#{year}-#{month}-#{day}")
  end
end
