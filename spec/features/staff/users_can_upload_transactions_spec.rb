RSpec.feature "users can upload transactions" do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:project) { create(:project_activity, :newton_funded, organisation: organisation) }
  let!(:sibling_project) { create(:project_activity, :newton_funded, organisation: organisation, parent: project.parent) }
  let!(:cousin_project) { create(:project_activity, :gcrf_funded, organisation: organisation) }

  let! :report do
    create(:report,
      state: :active,
      fund: project.associated_fund,
      organisation: organisation)
  end

  before do
    authenticate!(user: user)
    visit report_actuals_path(report)
    click_link t("action.transaction.upload.link")
  end

  def expect_to_see_successful_upload_summary_with(count:, total:)
    expect(page).to have_text(t("page_title.transaction.upload_success"))
    expect(page).to have_css(".transactions tr", count: count)
    expect(page).to have_link(
      t("importer.success.transaction.back_link"),
      href: report_actuals_path(report)
    )
    within ".totals" do
      expect(page).to have_content(total)
    end
  end

  scenario "they get helpful guidance and a link to actuals upload template on the upload page" do
    visit new_report_transaction_upload_path(report)

    expect(page.html).to include t("page_content.transactions.upload.copy_html",
      report_actuals_template_path: report_transaction_upload_path(report, format: :csv))
  end

  scenario "downloading a CSV template with activities for the current report" do
    visit report_transaction_upload_path(report, format: :csv)

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: true).map(&:to_h)

    expect(rows).to match_array([
      {
        "Activity Name" => project.title,
        "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
        "Activity RODA Identifier" => project.roda_identifier,
        "Financial Quarter" => report.financial_quarter.to_s,
        "Financial Year" => report.financial_year.to_s,
        "Value" => "0.00",
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
      },
      {
        "Activity Name" => sibling_project.title,
        "Activity Delivery Partner Identifier" => sibling_project.delivery_partner_identifier,
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Financial Quarter" => report.financial_quarter.to_s,
        "Financial Year" => report.financial_year.to_s,
        "Value" => "0.00",
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
      },
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.transaction.upload.button")
    expect(Transaction.count).to eq(0)
    expect(page).to have_text(t("action.transaction.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of transactions" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 20    | Example University          | 80                          |
      #{ids[1]}                | 1                 | 2020           | 30    | Example Foundation          | 60                          |
    CSV

    expect(Transaction.count).to eq(2)
    expect(page).to have_text(t("action.transaction.upload.success"))
    expect(page).not_to have_css("table.govuk-table.errors")

    expect_to_see_successful_upload_summary_with(count: 2, total: 50)
  end

  scenario "uploading a valid set of transactions with no organisation data" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 20    |                             |                             |
      #{ids[1]}                | 1                 | 2020           | 30    |                             |                             |
    CSV

    expect(Transaction.count).to eq(2)
    expect(page).to have_text(t("action.transaction.upload.success"))

    expect_to_see_successful_upload_summary_with(count: 2, total: 50)
  end

  scenario "uploading a valid set of transactions including zero values" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 0.00  | Example University          | 80                          |
      #{ids[1]}                | 1                 | 2020           | 30    | Example Foundation          | 60                          |
    CSV

    expect(Transaction.count).to eq(1)
    expect(page).to have_text(t("action.transaction.upload.success"))

    expect_to_see_successful_upload_summary_with(count: 1, total: 30)
  end

  scenario "uploading an invalid set of transactions" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | fish  | Example University          | 80                          |
      #{ids[1]}                | 1                 | 2020           | 30    | Example Foundation          | 61                          |
    CSV

    expect(Transaction.count).to eq(0)
    expect(page).not_to have_text(t("action.transaction.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Value")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "fish")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.transaction.non_numeric_value"))
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "Receiving Organisation Type")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "61")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.transaction.invalid_iati_organisation_type"))
    end
  end

  scenario "uploading a set of transactions with encoding errors" do
    ids = [project, sibling_project].map(&:roda_identifier)

    csv = <<~CSV
      Activity RODA Identifier,Financial Quarter,Financial Year,,Value,Receiving Organisation Name,Receiving Organisation Type,Receiving Organisation IATI Reference
      #{ids[0]},1,2020,\xA320,Example University,80
      #{ids[1]},1,2020,\xA330,Example Foundation,60
    CSV

    file = Tempfile.new("transactions.csv")
    file.write(csv)
    file.close

    attach_file "report[transaction_csv]", file.path
    click_button t("action.transaction.upload.button")

    file.unlink

    expect(Transaction.count).to eq(0)

    expect(page).to have_content(t("action.forecast.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of transactions with a BOM at the start of the file" do
    ids = [project, sibling_project].map(&:roda_identifier)
    bom = "\uFEFF"

    upload_csv bom + <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 20    | Example University          | 80                          |
      #{ids[1]}                | 2                 | 2020           | 30    | Example Foundation          | 60                          |
    CSV

    expect(Transaction.count).to eq(2)
    expect(page).to have_text(t("action.transaction.upload.success"))

    expect_to_see_successful_upload_summary_with(count: 2, total: 50)
  end

  def upload_csv(content)
    file = Tempfile.new("transactions.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[transaction_csv]", file.path
    click_button t("action.transaction.upload.button")

    file.unlink
  end
end
