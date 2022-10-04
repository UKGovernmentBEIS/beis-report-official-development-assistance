RSpec.feature "BEIS users can upload Level B budgets" do
  let(:user) { create(:beis_user) }
  let(:organisation) { create(:partner_organisation) }

  let!(:programme) {
    create(
      :programme_activity,
      :newton_funded,
      extending_organisation: create(:partner_organisation),
      roda_identifier: "AFUND-B-PROG",
      parent: create(:fund_activity, roda_identifier: "AFUND")
    )
  }

  before { authenticate!(user: user) }

  before do
    visit new_level_b_budgets_upload_path
  end

  after { logout }

  scenario "viewing the page for downloading or uploading a CSV template" do
    expect(page).to have_content(t("page_title.budget.upload_level_b"))
  end

  scenario "downloading the CSV template" do
    click_link t("action.budget.bulk_download.button")

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: false).first

    expect(rows).to match_array([
      "Type",
      "Financial year",
      "Budget amount",
      "Providing organisation",
      "Providing organisation type",
      "IATI reference",
      "Activity RODA ID",
      "Fund RODA ID",
      "Partner organisation name"
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.budget.upload.button")

    expect(page).to have_text(t("action.budget.upload.file_missing_or_invalid"))
  end

  scenario "uploading an empty file" do
    upload_empty_csv

    expect(page).to have_text(t("action.budget.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of budgets" do
    old_count = Budget.count

    attach_file "budget_upload[csv]", File.new("spec/fixtures/csv/valid_level_b_budgets_upload.csv").path
    click_button t("action.budget.upload.button")

    expect(Budget.count - old_count).to eq(2)

    visit organisation_activity_path(organisation, programme)

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "FY 2016-2017")
      expect(page).to have_xpath("td[2]", text: "Other official development assistance")
      expect(page).to have_xpath("td[3]", text: "£67,890.00")
      expect(page).to have_xpath("td[4]", text: "Lovely Co")
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "FY 2011-2012")
      expect(page).to have_xpath("td[2]", text: "Direct")
      expect(page).to have_xpath("td[3]", text: "£12,345.00")
      expect(page).to have_xpath("td[4]", text: "Department for Business, Energy and Industrial Strategy")
    end
  end

  scenario "uploading a set of activities with a BOM at the start" do
    freeze_time do
      attach_file "budget_upload[csv]", File.new("spec/fixtures/csv/valid_level_b_budgets_upload.csv").path
      click_button t("action.budget.upload.button")

      expect(page).to have_text(t("action.budget.upload.success"))

      new_budgets = Budget.where(created_at: DateTime.now)

      expect(new_budgets.count).to eq(2)
      expect(new_budgets.pluck(:value)).to match_array(["12345".to_d, "67890".to_d])
    end
  end

  scenario "uploading an invalid set of budgets" do
    old_count = Budget.count

    attach_file "budget_upload[csv]", File.new("spec/fixtures/csv/invalid_level_b_budgets_upload.csv").path
    click_button t("action.budget.upload.button")

    expect(Budget.count - old_count).to eq(0)
    expect(page).not_to have_text(t("action.budget.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Type")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "99999")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.budget.invalid_budget_type"))
    end

    within "//tbody/tr[4]" do
      expect(page).to have_xpath("td[1]", text: "Budget amount")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.budget.invalid_value"))
    end
  end

  scenario "upload a set of budgets from the error page after a failed upload" do
    2.times { upload_empty_csv }

    expect(page).to have_text(t("action.budget.upload.file_missing_or_invalid"))
  end

  def upload_csv(content)
    file = Tempfile.new("new_budgets.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "budget_upload[csv]", file.path
    click_button t("action.budget.upload.button")

    file.unlink
  end

  def upload_empty_csv
    upload_csv(Budget::Import::Converter::FIELDS.values.join(", "))
  end
end
