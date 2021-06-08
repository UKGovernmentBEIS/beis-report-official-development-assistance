RSpec.shared_examples "editing a transfer" do
  scenario "it shows the transfer details" do
    expect(page).to have_content(t("page_title.#{transfer_type}.edit"))

    if transfer_type == "outgoing_transfer"
      expect(page).to have_field("#{transfer_type}[destination_roda_identifier]", with: transfer.destination.roda_identifier)
    else
      expect(page).to have_field("#{transfer_type}[source_roda_identifier]", with: transfer.source.roda_identifier)
    end

    expect(page).to have_field("#{transfer_type}[financial_quarter]", with: transfer.financial_quarter, checked: true)
    expect(page).to have_selector("option[value='#{transfer.financial_year}'][selected='selected']")
    expect(page).to have_field("#{transfer_type}[value]", with: transfer.value)
  end

  scenario "the user can edit a transfer succesfully" do
    new_transfer = fill_in_transfer_form(type: transfer_type, value: 1234)

    click_on t("default.button.submit")

    expect(page).to have_content(t("page_title.#{transfer_type}.confirm"))

    if transfer_type == "outgoing_transfer"
      expect(page).to have_content(new_transfer.destination.title)
      expect(page).to have_content(new_transfer.destination.organisation.name)
    else
      expect(page).to have_content(new_transfer.source.title)
      expect(page).to have_content(new_transfer.source.organisation.name)
    end

    expect(page).to have_content(FinancialQuarter.new(new_transfer.financial_year, new_transfer.financial_quarter).to_s)
    expect(page).to have_content("£1,234.00")

    click_on "Yes"

    expect(page).to have_content(t("action.#{transfer_type}.update.success"))

    if transfer_type == "outgoing_transfer"
      expect(transfer.reload.destination).to eq(new_transfer.destination)
    else
      expect(transfer.reload.source).to eq(new_transfer.source)
    end

    expect(transfer.financial_year).to eq(new_transfer.financial_year)
    expect(transfer.financial_quarter).to eq(new_transfer.financial_quarter)
    expect(transfer.value).to eq(new_transfer.value)
  end

  scenario "the user can edit their response" do
    click_on t("default.button.submit")

    expect(page).to have_content(t("page_title.#{transfer_type}.confirm"))

    click_on "No"

    expect(page).to have_content(t("page_title.#{transfer_type}.edit"))

    new_transfer = fill_in_transfer_form(type: transfer_type)
    click_on t("default.button.submit")

    click_on "Yes"

    expect(page).to have_content(t("action.#{transfer_type}.update.success"))

    if transfer_type == "outgoing_transfer"
      expect(transfer.reload.destination).to eq(new_transfer.destination)
    else
      expect(transfer.reload.source).to eq(new_transfer.source)
    end

    expect(transfer.financial_year).to eq(new_transfer.financial_year)
    expect(transfer.financial_quarter).to eq(new_transfer.financial_quarter)
    expect(transfer.value).to eq(new_transfer.value)
  end

  scenario "the user can see validation errors" do
    non_existent_activity = build(:project_activity)

    roda_identifier = "GCRF-BLOB-424434434"
    allow(non_existent_activity).to receive(:roda_identifier) { roda_identifier }

    if transfer_type == "outgoing_transfer"
      fill_in_transfer_form(type: transfer_type, destination: non_existent_activity, value: nil)
    else
      fill_in_transfer_form(type: transfer_type, source: non_existent_activity, value: nil)
    end

    click_on t("default.button.submit")

    if transfer_type == "outgoing_transfer"
      expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.destination.required"))
      expect(page).to have_field("#{transfer_type}[destination_roda_identifier]", with: roda_identifier)
    else
      expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.source.required"))
      expect(page).to have_field("#{transfer_type}[source_roda_identifier]", with: roda_identifier)
    end

    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.value.blank"))
  end
end
