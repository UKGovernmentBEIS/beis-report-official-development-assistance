RSpec.shared_examples "creating a transfer" do
  let!(:report) { Report.for_activity(source_activity).create(state: "active") }

  before do
    visit organisation_activity_path(source_activity.organisation, source_activity)
    click_on "Transfer fund"
  end

  scenario "successfully creates a transfer" do
    quarter = FinancialQuarter.for_date(Date.today)

    transfer = fill_in_transfer_form(
      type: transfer_type,
      financial_quarter: quarter.to_i,
      financial_year: quarter.financial_year.to_i
    )

    click_on t("form.button.#{transfer_type}.submit")

    expect(page).to have_content(t("page_title.#{transfer_type}.confirm"))
    expect(page).to have_content(transfer.destination.title)
    expect(page).to have_content(transfer.destination.organisation.name)
    expect(page).to have_content(quarter.to_s)
    expect(page).to have_content("£1,234.00")

    expect {
      click_on "Yes"
    }.to change {
      OutgoingTransfer.count
    }.by(1)

    expect(page).to have_content(t("action.#{transfer_type}.create.success"))

    expect(created_transfer.source).to eq(source_activity)
    expect(created_transfer.destination).to eq(transfer.destination)
    expect(created_transfer.financial_quarter).to eq(transfer.financial_quarter)
    expect(created_transfer.financial_year).to eq(transfer.financial_year)
    expect(created_transfer.value).to eq(transfer.value)

    if source_activity.project? || source_activity.third_party_project?
      expect(created_transfer.report).to eq(report)
    end

    within "#transfers" do
      expect(page).to have_content(transfer.destination.roda_identifier)
      expect(page).to have_content(transfer.destination.organisation.name)
      expect(page).to have_content(quarter.to_s)
      expect(page).to have_content("£1,234.00")
    end
  end

  scenario "allows a transfer to be changed before creating" do
    transfer = fill_in_transfer_form(type: transfer_type, value: "1234")

    click_on t("form.button.#{transfer_type}.submit")

    expect(page).to have_content(t("page_title.#{transfer_type}.confirm"))

    click_on "No"

    expect(page).to have_content(t("page_title.#{transfer_type}.new"))
    expect(page).to have_field("#{transfer_type}[destination]", with: transfer.destination.roda_identifier)
    expect(page).to have_field("#{transfer_type}[financial_quarter]", with: transfer.financial_quarter, checked: true)
    expect(page).to have_selector("option[value='#{transfer.financial_year}'][selected='selected']")
    expect(page).to have_field("#{transfer_type}[value]", with: transfer.value)

    fill_in_transfer_form(type: transfer_type, value: "5678")
    click_on t("form.button.#{transfer_type}.submit")

    expect {
      click_on "Yes"
    }.to change {
      OutgoingTransfer.count
    }.by(1)

    expect(page).to have_content(t("action.#{transfer_type}.create.success"))

    expect(created_transfer.source).to eq(source_activity)
    expect(created_transfer.value).to eq(5678)
  end

  scenario "show an error when the destination RODA ID is incorrect" do
    non_existent_activity = build(:project_activity)

    roda_identifier = "GCRF-BLOB-424434434"
    allow(non_existent_activity).to receive(:roda_identifier) { roda_identifier }

    fill_in_transfer_form(type: transfer_type, destination: non_existent_activity)

    click_on t("form.button.#{transfer_type}.submit")

    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.destination.required"))
    expect(page).to have_field("#{transfer_type}[destination]", with: roda_identifier)
  end

  scenario "shows errors when required fields are blank" do
    expect {
      click_on t("form.button.#{transfer_type}.submit")
    }.to_not change {
      OutgoingTransfer.count
    }

    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.destination.required"))
    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.financial_quarter.blank"))
    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.value.blank"))
  end
end
