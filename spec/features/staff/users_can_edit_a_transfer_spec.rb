RSpec.feature "Delivery partner users can edit a transfer" do
  let(:user) { create(:delivery_partner_user) }
  before { authenticate!(user: user) }

  let(:source_activity) { create(:project_activity, organisation: user.organisation) }
  let(:destination_activity) { create(:project_activity) }
  let(:report) { Report.for_activity(source_activity).create(state: "active") }

  let!(:transfer) { create(:transfer, report: report, source: source_activity, destination: destination_activity) }

  before do
    visit organisation_activity_path(source_activity.organisation, source_activity)
    find("a[href='#{edit_activity_transfer_path(source_activity.id, transfer.id)}']").click
  end

  scenario "it shows the transfer details" do
    expect(page).to have_content(t("page_title.transfer.edit"))

    expect(page).to have_field("transfer[destination]", with: transfer.destination.roda_identifier)
    expect(page).to have_field("transfer[financial_quarter]", with: transfer.financial_quarter, checked: true)
    expect(page).to have_selector("option[value='#{transfer.financial_year}'][selected='selected']")
    expect(page).to have_field("transfer[value]", with: transfer.value)
  end

  scenario "the user can edit a transfer succesfully" do
    new_transfer = fill_in_transfer_form(value: 1234)

    click_on t("default.button.submit")

    expect(page).to have_content(t("page_title.transfer.confirm"))
    expect(page).to have_content(new_transfer.destination.title)
    expect(page).to have_content(new_transfer.destination.organisation.name)
    expect(page).to have_content(FinancialQuarter.new(new_transfer.financial_year, new_transfer.financial_quarter).to_s)
    expect(page).to have_content("£1,234.00")

    click_on "Yes"

    expect(page).to have_content(t("action.transfer.update.success"))

    expect(transfer.reload.destination).to eq(new_transfer.destination)
    expect(transfer.financial_year).to eq(new_transfer.financial_year)
    expect(transfer.financial_quarter).to eq(new_transfer.financial_quarter)
    expect(transfer.value).to eq(new_transfer.value)
  end

  scenario "the user can edit their response" do
    click_on t("default.button.submit")

    expect(page).to have_content(t("page_title.transfer.confirm"))

    click_on "No"

    expect(page).to have_content(t("page_title.transfer.edit"))

    new_transfer = fill_in_transfer_form
    click_on t("default.button.submit")

    click_on "Yes"

    expect(page).to have_content(t("action.transfer.update.success"))

    expect(transfer.reload.destination).to eq(new_transfer.destination)
    expect(transfer.financial_year).to eq(new_transfer.financial_year)
    expect(transfer.financial_quarter).to eq(new_transfer.financial_quarter)
    expect(transfer.value).to eq(new_transfer.value)
  end

  scenario "the user can see validation errors" do
    non_existent_activity = build(:project_activity)

    roda_identifier = "GCRF-BLOB-424434434"
    allow(non_existent_activity).to receive(:roda_identifier) { roda_identifier }

    fill_in_transfer_form(destination: non_existent_activity, value: nil)

    click_on t("default.button.submit")

    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.destination.required"))
    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.value.blank"))

    expect(page).to have_field("transfer[destination]", with: roda_identifier)
  end
end
