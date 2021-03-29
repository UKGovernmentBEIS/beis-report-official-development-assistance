RSpec.feature "users can upload planned disbursements" do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:project) { create(:project_activity, organisation: organisation) }
  let!(:sibling_project) { create(:project_activity, organisation: organisation, parent: project.parent) }
  let!(:cousin_project) { create(:project_activity, organisation: organisation) }

  let! :report do
    create(:report,
      state: :active,
      fund: project.associated_fund,
      organisation: organisation,
      financial_year: 2021,
      financial_quarter: 1)
  end

  before do
    authenticate!(user: user)
    visit report_path(report)
    click_link t("action.planned_disbursement.upload.link")
  end

  describe "downloading a CSV template with activities for the current report" do
    before do
      click_link t("action.planned_disbursement.download.button")
      @csv_data = page.body.delete_prefix("\uFEFF")
    end

    it "lists the name and ID of all reportable activities" do
      rows = CSV.parse(@csv_data, headers: true).map(&:to_h)
      activity_data = rows.map { |row| row.reject { |key, _| key =~ /^FC / } }

      expect(activity_data).to match_array([
        {
          "Activity Name" => project.title,
          "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
          "Activity RODA Identifier" => project.roda_identifier,
        },
        {
          "Activity Name" => sibling_project.title,
          "Activity Delivery Partner Identifier" => sibling_project.delivery_partner_identifier,
          "Activity RODA Identifier" => sibling_project.roda_identifier,
        },
      ])
    end

    it "incldues headings for all reportable quarters" do
      headings = CSV.parse(@csv_data).first.to_a

      expect(headings).to eq([
        "Activity Name", "Activity Delivery Partner Identifier", "Activity RODA Identifier",
        "FC 2021/22 FY Q2", "FC 2021/22 FY Q3", "FC 2021/22 FY Q4", "FC 2022/23 FY Q1",
        "FC 2022/23 FY Q2", "FC 2022/23 FY Q3", "FC 2022/23 FY Q4", "FC 2023/24 FY Q1",
        "FC 2023/24 FY Q2", "FC 2023/24 FY Q3", "FC 2023/24 FY Q4", "FC 2024/25 FY Q1",
        "FC 2024/25 FY Q2", "FC 2024/25 FY Q3", "FC 2024/25 FY Q4", "FC 2025/26 FY Q1",
        "FC 2025/26 FY Q2", "FC 2025/26 FY Q3", "FC 2025/26 FY Q4", "FC 2026/27 FY Q1",
      ])
    end

    it "puts no value in all forecast columns by default" do
      rows = CSV.parse(@csv_data, headers: true).map(&:to_h)

      expect(rows.first).to eq({
        "Activity Name" => project.title,
        "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
        "Activity RODA Identifier" => project.roda_identifier,

        "FC 2021/22 FY Q2" => "",
        "FC 2021/22 FY Q3" => "",
        "FC 2021/22 FY Q4" => "",
        "FC 2022/23 FY Q1" => "",

        "FC 2022/23 FY Q2" => "",
        "FC 2022/23 FY Q3" => "",
        "FC 2022/23 FY Q4" => "",
        "FC 2023/24 FY Q1" => "",

        "FC 2023/24 FY Q2" => "",
        "FC 2023/24 FY Q3" => "",
        "FC 2023/24 FY Q4" => "",
        "FC 2024/25 FY Q1" => "",

        "FC 2024/25 FY Q2" => "",
        "FC 2024/25 FY Q3" => "",
        "FC 2024/25 FY Q4" => "",
        "FC 2025/26 FY Q1" => "",

        "FC 2025/26 FY Q2" => "",
        "FC 2025/26 FY Q3" => "",
        "FC 2025/26 FY Q4" => "",
        "FC 2026/27 FY Q1" => "",
      })
    end
  end

  scenario "not uploading a file" do
    click_button t("action.planned_disbursement.upload.button")
    expect(PlannedDisbursement.count).to eq(0)
    expect(page).to have_text(t("action.planned_disbursement.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of forecasts" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | 50               | 60
    CSV

    expect(PlannedDisbursement.count).to eq(6)
    expect(page).to have_text(t("action.planned_disbursement.upload.success"))
    expect(page).not_to have_xpath("//tbody/tr")
  end

  scenario "uploading an invalid set of forecasts" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | not a number     | 60
    CSV

    expect(PlannedDisbursement.count).to eq(0)
    expect(page).not_to have_text(t("action.planned_disbursement.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "FC 2021/22 FY Q3")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "not a number")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.planned_disbursement.non_numeric_value"))
    end
  end

  scenario "uploading a partially completed template" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               |                  |
      #{ids[1]}                | 40               |                  | 60
    CSV

    expect(PlannedDisbursement.count).to eq(3)
    expect(page).to have_text(t("action.planned_disbursement.upload.success"))
    expect(page).not_to have_xpath("//tbody/tr")
  end

  scenario "uploading a set of forecasts with encoding errors" do
    ids = [project, sibling_project].map(&:roda_identifier)

    file = Tempfile.new("forecasts.csv")
    csv = <<~CSV
      Activity RODA Identifier,FC 2021/22 FY Q2,FC 2021/22 FY Q3,FC 2021/22 FY Q4
      #{ids[0]},10,\xA320,30
      #{ids[1]},40,\xA350,60
    CSV
    file.write(csv)
    file.close

    attach_file "report[planned_disbursement_csv]", file.path
    click_button t("action.planned_disbursement.upload.button")

    file.unlink

    expect(PlannedDisbursement.count).to eq(0)

    expect(page).to have_content(t("action.planned_disbursement.upload.file_missing_or_invalid"))
  end

  scenario "uploading a set of forecasts with a BOM at the start of the file" do
    ids = [project, sibling_project].map(&:roda_identifier)
    bom = "\uFEFF"

    upload_csv bom + <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | 50               | 60
    CSV

    expect(PlannedDisbursement.count).to eq(6)
    expect(page).to have_text(t("action.planned_disbursement.upload.success"))
    expect(page).not_to have_xpath("//tbody/tr")
  end

  def upload_csv(content)
    file = Tempfile.new("forecasts.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[planned_disbursement_csv]", file.path
    click_button t("action.planned_disbursement.upload.button")

    file.unlink
  end
end
