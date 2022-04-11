module FormHelpers
  include ActivityHelper

  def fill_in_actual_form(expectations: true,
    value: "1000.01",
    financial_quarter: "4",
    financial_year: "2019-2020",
    comment: nil,
    receiving_organisation: OpenStruct.new(name: "Example receiver", reference: "GB-COH-123", type: "Private Sector"))

    fill_in "Actual amount", with: value
    choose financial_quarter, name: "actual_form[financial_quarter]"
    select financial_year, from: "Financial year"
    fill_in "Receiving organisation name", with: receiving_organisation.name
    select receiving_organisation.type, from: "Receiving organisation type" if receiving_organisation.type.present?
    fill_in "IATI Reference (optional)", with: receiving_organisation.reference
    fill_in "Comment", with: comment if comment

    click_on(t("default.button.submit"))

    if expectations
      within ".actuals" do
        start_year = financial_year.split("-").first.to_i
        expect(page).to have_content(FinancialQuarter.new(start_year, financial_quarter).to_s)
        expect(page).to have_content(ActionController::Base.helpers.number_to_currency(value, unit: "£"))
        expect(page).to have_content(receiving_organisation.name)
      end
    end
  end

  def fill_in_forecast_form(
    financial_quarter: "Q2",
    financial_year: "2020-2021",
    value: "100000"
  )

    choose financial_quarter
    select financial_year, from: "Financial year"

    fill_in "forecast[value]", with: value

    click_on(t("default.button.submit"))
  end

  def fill_in_forecast_form_for_activity(activity)
    report = Report.editable_for_activity(activity)
    year = report.financial_year

    fill_in_forecast_form(
      financial_quarter: "Q#{report.financial_quarter}",
      financial_year: "#{year + 1}-#{year + 2}"
    )
  end

  def fill_in_transfer_form(type:, destination: create(:project_activity), source: create(:project_activity), financial_quarter: FinancialQuarter.for_date(Date.today).to_i, financial_year: FinancialYear.for_date(Date.today).to_i, value: 1234, beis_identifier: nil)
    transfer = build(
      type,
      destination: destination,
      source: source,
      financial_quarter: financial_quarter,
      financial_year: financial_year,
      value: value
    )

    if type == "outgoing_transfer"
      fill_in "outgoing_transfer[destination_roda_identifier]", with: transfer.destination.roda_identifier
    else
      fill_in "incoming_transfer[source_roda_identifier]", with: transfer.source.roda_identifier
    end

    fill_in "#{type}[beis_identifier]", with: beis_identifier if beis_identifier
    choose transfer.financial_quarter.to_s, name: "#{type}[financial_quarter]"
    select transfer.financial_year, from: "#{type}[financial_year]"
    fill_in "#{type}[value]", with: transfer.value

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
    current_year = FinancialYear.new(Date.today.year).to_s
    page.find(:xpath, "//input[@value='#{template.financial_quarter}']").set(true)
    select current_year, from: "external_income[financial_year]"
    select template.organisation.name, from: "external_income[organisation_id]"
    fill_in "external_income[amount]", with: template.amount
    check "external_income[oda_funding]" if template.oda_funding
    uncheck "external_income[oda_funding]" unless template.oda_funding

    click_on t("default.button.submit")
  end
end
