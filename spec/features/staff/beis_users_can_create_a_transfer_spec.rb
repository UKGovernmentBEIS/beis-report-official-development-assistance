RSpec.feature "BEIS users can create a transfer" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  let(:source_activity) { create(:activity) }
  let(:created_transfer) { Transfer.last }

  before do
    visit organisation_activity_path(source_activity.organisation, source_activity)
    click_on "Transfer fund"
  end

  scenario "successfully creates a transfer" do
    transfer = fill_in_transfer_form

    click_on t("form.button.transfer.submit")

    expect(page).to have_content(t("page_title.transfer.confirm"))
    expect(page).to have_content(transfer.destination.title)
    expect(page).to have_content(transfer.destination.organisation.name)
    expect(page).to have_content(FinancialQuarter.new(2020, 1).to_s)
    expect(page).to have_content("£1,234.00")

    expect {
      click_on "Yes"
    }.to change {
      Transfer.count
    }.by(1)

    expect(page).to have_content(t("action.transfer.create.success"))

    expect(created_transfer.source).to eq(source_activity)
    expect(created_transfer.destination).to eq(transfer.destination)
    expect(created_transfer.financial_quarter).to eq(transfer.financial_quarter)
    expect(created_transfer.financial_year).to eq(transfer.financial_year)
    expect(created_transfer.value).to eq(transfer.value)
  end

  scenario "allows a transfer to be changed before creating" do
    transfer = fill_in_transfer_form(value: "1234")

    click_on t("form.button.transfer.submit")

    expect(page).to have_content(t("page_title.transfer.confirm"))

    click_on "No"

    expect(page).to have_content(t("page_title.transfer.new"))
    expect(page).to have_field("transfer[destination]", with: transfer.destination.roda_identifier)
    expect(page).to have_field("transfer[financial_quarter]", with: transfer.financial_quarter, checked: true)
    expect(page).to have_selector("option[value='#{transfer.financial_year}'][selected='selected']")
    expect(page).to have_field("transfer[value]", with: transfer.value)

    fill_in_transfer_form(value: "5678")
    click_on t("form.button.transfer.submit")

    expect {
      click_on "Yes"
    }.to change {
      Transfer.count
    }.by(1)

    expect(page).to have_content(t("action.transfer.create.success"))

    expect(created_transfer.source).to eq(source_activity)
    expect(created_transfer.value).to eq(5678)
  end

  scenario "show an error when the destination RODA ID is incorrect" do
    non_existent_activity = build(:activity)
    fill_in_transfer_form(destination: non_existent_activity)

    click_on t("form.button.transfer.submit")

    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.destination.required"))
    expect(page).to have_field("transfer[destination]", with: non_existent_activity.roda_identifier)
  end

  scenario "shows errors when required fields are blank" do
    expect {
      click_on t("form.button.transfer.submit")
    }.to_not change {
      Transfer.count
    }

    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.destination.required"))
    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.financial_quarter.blank"))
    expect(page).to have_content(t("activerecord.errors.models.transfer.attributes.value.blank"))
  end
end
