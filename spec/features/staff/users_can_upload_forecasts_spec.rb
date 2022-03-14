RSpec.feature "users can upload forecasts" do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:project) { create(:project_activity, :newton_funded, organisation: organisation) }
  let!(:sibling_project) { create(:project_activity, :newton_funded, organisation: organisation, parent: project.parent) }
  let!(:cousin_project) { create(:project_activity, :gcrf_funded, organisation: organisation) }

  let! :report do
    create(:report,
      :active,
      fund: project.associated_fund,
      organisation: organisation,
      financial_year: 2021,
      financial_quarter: 1)
  end

  before do
    authenticate!(user: user)
    visit report_forecasts_path(report)
    click_link "Upload forecast data"
  end

  def expect_to_see_successful_upload_summary_with(count:, total:)
    expect(page).to have_text("Successful uploads")
    expect(page).to have_css(".forecasts tr", count: count)
    expect(page).to have_link(
      "Back to report",
      href: report_forecasts_path(report)
    )
    within ".totals" do
      expect(page).to have_content(total)
    end
  end

  describe "downloading a CSV template with activities for the current report" do
    before do
      click_link "Download CSV template"
      @csv_data = page.body.delete_prefix("\uFEFF")
    end

    it "lists the name and ID of all reportable activities" do
      rows = CSV.parse(@csv_data, headers: true).map(&:to_h)
      activity_data = rows.map { |row| row.reject { |key, _| key =~ /^FC / } }

      expect(activity_data).to match_array([
        {
          "Activity Name" => project.title,
          "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
          "Activity RODA Identifier" => project.roda_identifier
        },
        {
          "Activity Name" => sibling_project.title,
          "Activity Delivery Partner Identifier" => sibling_project.delivery_partner_identifier,
          "Activity RODA Identifier" => sibling_project.roda_identifier
        }
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
        "FC 2025/26 FY Q2", "FC 2025/26 FY Q3", "FC 2025/26 FY Q4", "FC 2026/27 FY Q1"
      ])
    end

    it "puts no value in all forecast columns by default" do
      rows = CSV.parse(@csv_data, headers: true).map(&:to_h)
      expect(rows.size).to eq(2)

      rows.each do |row|
        expect(row).to match hash_including(
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
          "FC 2026/27 FY Q1" => ""
        )
      end
    end
  end

  scenario "not uploading a file" do
    click_button "Upload and continue"
    expect(Forecast.unscoped.count).to eq(0)
    expect(page).to have_text("Please upload a valid CSV file")
  end

  scenario "uploading a valid set of forecasts" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | -50              | 60
    CSV

    expect(Forecast.unscoped.count).to eq(6)
    expect(page).to have_text("The forecasts were successfully imported.")
    expect_to_see_successful_upload_summary_with(count: 6, total: "£110.00")
  end

  scenario "uploading an invalid set of forecasts" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | not a number     | 60
    CSV

    expect(Forecast.unscoped.count).to eq(0)
    expect(page).not_to have_text("The forecasts were successfully imported.")

    # upload info not present
    expect(page).not_to have_text("Successful uploads")
    expect(page).not_to have_link("Back to report")

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "FC 2021/22 FY Q3")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "not a number")
      expect(page).to have_xpath("td[4]", text: "The value must be numeric")
    end
  end

  scenario "uploading a partially completed template" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               |                  |
      #{ids[1]}                | 40               |                  | 60
    CSV

    expect(Forecast.unscoped.count).to eq(3)
    expect(page).to have_text("The forecasts were successfully imported.")
    expect_to_see_successful_upload_summary_with(count: 3, total: "£110.00")
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

    attach_file "report[forecast_csv]", file.path
    click_button "Upload and continue"

    file.unlink

    expect(Forecast.unscoped.count).to eq(0)

    expect(page).to have_content("Please upload a valid CSV file")
  end

  scenario "uploading a set of forecasts with a BOM at the start of the file" do
    ids = [project, sibling_project].map(&:roda_identifier)
    bom = "\uFEFF"

    upload_csv bom + <<~CSV
      Activity RODA Identifier | FC 2021/22 FY Q2 | FC 2021/22 FY Q3 | FC 2021/22 FY Q4
      #{ids[0]}                | 10               | 20               | 30
      #{ids[1]}                | 40               | 50               | 60
    CSV

    expect(Forecast.unscoped.count).to eq(6)
    expect(page).to have_text("The forecasts were successfully imported.")
    expect_to_see_successful_upload_summary_with(count: 6, total: "£210.00")
  end

  def upload_csv(content)
    file = Tempfile.new("forecasts.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[forecast_csv]", file.path
    click_button "Upload and continue"

    file.unlink
  end
end
