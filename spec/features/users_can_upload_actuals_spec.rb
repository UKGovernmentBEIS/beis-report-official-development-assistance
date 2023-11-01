RSpec.feature "users can upload actuals" do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }

  let!(:project) { create(:project_activity, :newton_funded, organisation: organisation, is_oda: true) }
  let!(:sibling_project) { create(:project_activity, :newton_funded, organisation: organisation, parent: project.parent, is_oda: true) }
  let!(:cousin_project) { create(:project_activity, :gcrf_funded, organisation: organisation, is_oda: true) }

  let! :report do
    create(:report,
      :active,
      fund: project.associated_fund,
      organisation: organisation,
      is_non_oda: false)
  end

  before do
    authenticate!(user: user)
    visit report_actuals_path(report)
    click_link t("page_content.actuals.button.upload")
  end

  after { logout }

  def expect_to_see_successful_upload_summary_with(count:, total:)
    expect(page).to have_text(t("page_title.actual.upload_success"))
    expect(page).to have_css(".actuals tr", count: count)
    expect(page).to have_link(
      t("action.actual.upload.back_link"),
      href: report_actuals_path(report)
    )
    within ".totals" do
      expect(page).to have_content(total)
    end
  end

  scenario "they get helpful guidance and a link to actuals upload template on the upload page" do
    visit new_report_actuals_upload_path(report)

    expect(page.html).to include t("page_content.actuals.upload.copy_html",
      report_actuals_template_path: report_actuals_upload_path(report, format: :csv))

    expect(page).to have_text("Uploading actuals and refunds data is an append operation. Uploading the same data twice will result in duplication. See the guidance for more details.")
    expect(page.html).to include t("action.actual.upload.back_link")
  end

  scenario "downloading a CSV template with activities for the current report" do
    visit report_actuals_upload_path(report, format: :csv)

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: true).map(&:to_h)

    expect(rows).to match_array([
      {
        "Activity Name" => project.title,
        "Activity Partner Organisation Identifier" => project.partner_organisation_identifier,
        "Activity RODA Identifier" => project.roda_identifier,
        "Financial Quarter" => report.financial_quarter.to_s,
        "Financial Year" => report.financial_year.to_s,
        "Actual Value" => "0.00",
        "Refund Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
        "Comment" => nil
      },
      {
        "Activity Name" => sibling_project.title,
        "Activity Partner Organisation Identifier" => sibling_project.partner_organisation_identifier,
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Financial Quarter" => report.financial_quarter.to_s,
        "Financial Year" => report.financial_year.to_s,
        "Actual Value" => "0.00",
        "Refund Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
        "Comment" => nil
      }
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.actual.upload.button")
    expect(Actual.count).to eq(0)
    expect(page).to have_text(t("action.actual.upload.file_missing_or_invalid"))
    expect(page).to have_link(
      t("action.actual.upload.back_link"),
      href: report_actuals_path(report)
    )
  end

  scenario "uploading a valid set of actuals and refunds" do
    # Given that I am logged in as a partner organisation user
    # And a report exists that is waiting for actuals to be uploaded

    ids = [project, sibling_project].map(&:roda_identifier)

    # When I upload some actuals with comments
    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{ids[0]}                | 1                 | 2020           | 20           |              | Example University          | 80                          |                                       | A unique comment
      #{ids[1]}                | 1                 | 2020           | 30           |              | Example Foundation          | 60                          |                                       |
      #{ids[1]}                | 1                 | 2020           | 0            | -2           | Example Foundation          | 60                          |                                       | Underspent
    CSV

    # Then I should see a summary of my upload
    expect(Actual.count).to eq(2)
    expect(Refund.count).to eq(1)
    expect(page).to have_text(t("action.actual.upload.success"))
    expect(page).not_to have_css("table.govuk-table.errors")
    expect(page).to have_text("A unique comment")

    # two Actual rows, one comment
    expect_to_see_successful_upload_summary_with(count: 5, total: 48)

    # When I go back to the report
    click_on "Back to report"
    expect(page).to have_text("A unique comment")

    # And I open the comments tab
    click_on "Comments"
    # Then I should see my actuals comment is there
    expect(page).to have_text("A unique comment")
  end

  scenario "uploading a valid set of actuals with no organisation data" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 20           |                             |                             |
      #{ids[1]}                | 1                 | 2020           | 30           |                             |                             |
    CSV

    expect(Actual.count).to eq(2)
    expect(page).to have_text(t("action.actual.upload.success"))

    expect_to_see_successful_upload_summary_with(count: 2, total: 50)
  end

  scenario "uploading a valid actual alongside an (invalid) default value row (without a comment)" do
    upload_csv <<~CSV
      Activity RODA Identifier   | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{project.roda_identifier} | 1                 | 2020           | 5            |              |                             |                             |                                       |
      #{project.roda_identifier} | 2                 | 2020           | 0            |              |                             |                             |                                       |
    CSV

    expect(Actual.count).to eq(1)
    expect(page).to have_text(t("action.actual.upload.success"))
    expect(page).not_to have_css("table.govuk-table.errors")
    expect_to_see_successful_upload_summary_with(count: 1, total: 5)
  end

  scenario "uploading an invalid set of actuals" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier   | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{ids[0]}                  | 1                 | 2020           | fish         |              | Example University          | 80                          |                                       |
      #{ids[1]}                  | 1                 | 2020           | 30           |              | Example Foundation          | 61                          |                                       |
      #{ids[0]}                  | 1                 | 2020           | 0            |              |                             |                             |                                       |
      #{ids[0]}                  | 1                 | 2020           | 4            | 5            |                             |                             |                                       |
      #{ids[0]}                  | 1                 | 2020           | 5            | 0            |                             |                             |                                       |
      #{ids[0]}                  | 1                 | 2020           | 0            | 0            |                             |                             |                                       |
      #{ids[0]}                  | 1                 | 2020           |              | 0            |                             |                             |                                       |
      #{ids[0]}                  | 1                 | 2020           |              |              |                             |                             |                                       |
    CSV

    expect(Actual.count).to eq(0)
    expect(page).not_to have_text(t("action.actual.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "fish")
      expect(page).to have_xpath("td[4]", text: "Actual and refund values must be blank or numeric")
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "Receiving Organisation Type")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "61")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.actual.invalid_iati_organisation_type"))
    end

    within "//tbody/tr[3]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "4")
      expect(page).to have_xpath("td[3]", text: "0, blank")
      expect(page).to have_xpath("td[4]", text: "Actual can't be zero when refund is blank")
    end

    within "//tbody/tr[4]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "5")
      expect(page).to have_xpath("td[3]", text: "4, 5")
      expect(page).to have_xpath("td[4]", text: "Actual and refund are both filled")
    end

    within "//tbody/tr[5]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "6")
      expect(page).to have_xpath("td[3]", text: "5, 0")
      expect(page).to have_xpath("td[4]", text: "Refund can't be zero when actual is filled")
    end

    within "//tbody/tr[6]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "7")
      expect(page).to have_xpath("td[3]", text: "0, 0")
      expect(page).to have_xpath("td[4]", text: "Actual and refund are both zero")
    end

    within "//tbody/tr[7]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "8")
      expect(page).to have_xpath("td[3]", text: "blank, 0")
      expect(page).to have_xpath("td[4]", text: "Refund can't be zero when actual is blank")
    end

    within "//tbody/tr[8]" do
      expect(page).to have_xpath("td[1]", text: "Actual Value/Refund Value")
      expect(page).to have_xpath("td[2]", text: "9")
      expect(page).to have_xpath("td[3]", text: "blank, blank")
      expect(page).to have_xpath("td[4]", text: "Actual and refund are both blank")
    end
  end

  scenario "uploading invalid values with a comment" do
    upload_csv <<~CSV
      Activity RODA Identifier   | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{project.roda_identifier} | 1                 | 2020           | 0            | 0            |                             |                             |                                       | Woo!
    CSV

    expect(Actual.count).to eq(0)
    expect(page).not_to have_text("The transactions were successfully imported.")
    expect(page).to have_text("Comments can only be added via the bulk upload if they have an accompanying actual or refund value. If this is not the case, you will need to add the comment via the comments section of relevant activity.")
  end

  scenario "uploading invalid values without a comment" do
    upload_csv <<~CSV
      Activity RODA Identifier   | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{project.roda_identifier} | 1                 | 2020           | 0            | 0            |                             |                             |                                       |
    CSV

    expect(Actual.count).to eq(0)
    expect(page).not_to have_text("The transactions were successfully imported.")
    expect(page).not_to have_text("Comments can only be added via the bulk upload if they have an accompanying actual or refund value. If this is not the case, you will need to add the comment via the comments section of relevant activity.")
    expect(page).to have_link(
      t("action.actual.upload.back_link"),
      href: report_actuals_path(report)
    )
  end

  scenario "uploading a set of actuals with encoding errors" do
    ids = [project, sibling_project].map(&:roda_identifier)

    csv = <<~CSV
      Activity RODA Identifier,Financial Quarter,Financial Year,,Actual Value,Receiving Organisation Name,Receiving Organisation Type,Receiving Organisation IATI Reference
      #{ids[0]},1,2020,\xA320,Example University,80
      #{ids[1]},1,2020,\xA330,Example Foundation,60
    CSV

    file = Tempfile.new("actuals.csv")
    file.write(csv)
    file.close

    attach_file "report[actual_csv]", file.path
    click_button t("action.actual.upload.button")

    file.unlink

    expect(Actual.count).to eq(0)

    expect(page).to have_content(t("action.forecast.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of actuals with a BOM at the start of the file" do
    ids = [project, sibling_project].map(&:roda_identifier)
    bom = "\uFEFF"

    upload_csv bom + <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 1                 | 2020           | 20           | Example University          | 80                          |
      #{ids[1]}                | 2                 | 2020           | 30           | Example Foundation          | 60                          |
    CSV

    expect(Actual.count).to eq(2)
    expect(page).to have_text(t("action.actual.upload.success"))

    expect_to_see_successful_upload_summary_with(count: 2, total: 50)
  end

  def upload_csv(content)
    file = Tempfile.new("actuals.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[actual_csv]", file.path
    click_button t("action.actual.upload.button")

    file.unlink
  end
end
