RSpec.shared_examples "creating a transfer" do
  let!(:report) { Report.for_activity(target_activity).create(state: "active") }
  let(:transfer_model) { transfer_type == "outgoing_transfer" ? OutgoingTransfer : IncomingTransfer }

  before do
    visit organisation_activity_transfers_path(target_activity.organisation, target_activity)
    click_on t("form.button.#{transfer_type}.create")
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
    if transfer_type == "outgoing_transfer"
      expect(page).to have_content(transfer.destination.title)
      expect(page).to have_content(transfer.destination.organisation.name)
    else
      expect(page).to have_content(transfer.source.title)
      expect(page).to have_content(transfer.source.organisation.name)
    end
    expect(page).to have_content(quarter.to_s)
    expect(page).to have_content("£1,234.00")

    expect {
      click_on "Yes"
    }.to change {
      transfer_model.count
    }.by(1)

    expect(page).to have_content(t("action.#{transfer_type}.create.success"))

    if transfer_type == "outgoing_transfer"
      expect(created_transfer.source).to eq(target_activity)
      expect(created_transfer.destination).to eq(transfer.destination)
    else
      expect(created_transfer.destination).to eq(target_activity)
      expect(created_transfer.source).to eq(transfer.source)
    end

    expect(created_transfer.financial_quarter).to eq(transfer.financial_quarter)
    expect(created_transfer.financial_year).to eq(transfer.financial_year)
    expect(created_transfer.value).to eq(transfer.value)

    if target_activity.project? || target_activity.third_party_project?
      expect(created_transfer.report).to eq(report)
    end

    within "##{transfer_type.pluralize}" do
      if transfer_type == "outgoing_transfer"
        expect(page).to have_content(transfer.destination.roda_identifier)
        expect(page).to have_content(transfer.destination.organisation.name)
      else
        expect(page).to have_content(transfer.source.roda_identifier)
        expect(page).to have_content(transfer.source.organisation.name)
      end

      expect(page).to have_content(quarter.to_s)
      expect(page).to have_content("£1,234.00")
    end
  end

  scenario "records the BEIS identifier if provided" do
    fill_in_transfer_form(type: transfer_type, value: "1234", beis_identifier: "historic-tracker-id")
    click_on t("form.button.#{transfer_type}.submit")
    expect(page).to have_content("historic-tracker-id")

    click_on "Yes"
    expect(created_transfer.beis_identifier).to eq("historic-tracker-id")

    within "##{transfer_type.pluralize}" do
      expect(page).to have_content("historic-tracker-id")
    end
  end

  scenario "allows a transfer to be changed before creating" do
    transfer = fill_in_transfer_form(type: transfer_type, value: "1234")

    click_on t("form.button.#{transfer_type}.submit")

    expect(page).to have_content(t("page_title.#{transfer_type}.confirm"))

    click_on "No"

    expect(page).to have_content(t("page_title.#{transfer_type}.new"))

    if transfer_type == "outgoing_transfer"
      expect(page).to have_field("#{transfer_type}[destination_roda_identifier]", with: transfer.destination.roda_identifier)
    else
      expect(page).to have_field("#{transfer_type}[source_roda_identifier]", with: transfer.source.roda_identifier)
    end

    expect(page).to have_field("#{transfer_type}[financial_quarter]", with: transfer.financial_quarter, checked: true)
    expect(page).to have_selector("option[value='#{transfer.financial_year}'][selected='selected']")
    expect(page).to have_field("#{transfer_type}[value]", with: transfer.value)

    fill_in_transfer_form(type: transfer_type, value: "5678")
    click_on t("form.button.#{transfer_type}.submit")

    expect {
      click_on "Yes"
    }.to change {
      transfer_model.count
    }.by(1)

    expect(page).to have_content(t("action.#{transfer_type}.create.success"))

    if transfer_type == "outgoing_transfer"
      expect(created_transfer.source).to eq(target_activity)
    else
      expect(created_transfer.destination).to eq(target_activity)
    end

    expect(created_transfer.value).to eq(5678)
  end

  scenario "show an error when the destination RODA ID is incorrect" do
    non_existent_activity = build(:project_activity)

    roda_identifier = "GCRF-BLOB-424434434"
    allow(non_existent_activity).to receive(:roda_identifier) { roda_identifier }

    if transfer_type == "outgoing_transfer"
      fill_in_transfer_form(type: transfer_type, destination: non_existent_activity)
    else
      fill_in_transfer_form(type: transfer_type, source: non_existent_activity)
    end

    click_on t("form.button.#{transfer_type}.submit")

    if transfer_type == "outgoing_transfer"
      expect(page).to have_content(t("activerecord.errors.models.outgoing_transfer.attributes.destination.required"))
      expect(page).to have_field("#{transfer_type}[destination_roda_identifier]", with: roda_identifier)
    else
      expect(page).to have_content(t("activerecord.errors.models.incoming_transfer.attributes.source.required"))
      expect(page).to have_field("#{transfer_type}[source_roda_identifier]", with: roda_identifier)
    end
  end

  scenario "shows errors when required fields are blank" do
    expect {
      click_on t("form.button.#{transfer_type}.submit")
    }.to_not change {
      transfer_model.count
    }

    if transfer_type == "outgoing_transfer"
      expect(page).to have_content(t("activerecord.errors.models.outgoing_transfer.attributes.destination.required"))
    else
      expect(page).to have_content(t("activerecord.errors.models.incoming_transfer.attributes.source.required"))
    end

    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.financial_quarter.blank"))
    expect(page).to have_content(t("activerecord.errors.models.#{transfer_type}.attributes.value.blank"))
  end
end
