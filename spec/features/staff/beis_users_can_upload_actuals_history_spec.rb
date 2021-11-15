RSpec.feature "BEIS users upload actual history" do
  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:report) { create(:report) }

    before { authenticate!(user: beis_user) }

    scenario "they can see the actuals history upload interface" do
      visit report_actuals_path(report)

      expect(page).to have_content(t("actions.uploads.actual_histories.new_upload"))
    end

    scenario "they can provide a file" do
      file_content =
        <<~CSV
          Activity Name|Activity Delivery Partner Identifier|Activity RODA Identifier|Financial Quarter|Financial Year|Value
          Activity A|DPID|RODAID|4|2021|10_000
        CSV

      visit new_report_uploads_actual_history_path(report)
      upload_fixture(file_content)

      expect(page).to have_content(t("actions.uploads.actual_histories.success"))
    end

    scenario "when the file is missing" do
      visit new_report_uploads_actual_history_path(report)
      click_button t("actions.uploads.actual_histories.upload.button")

      expect(page).to have_content(t("actions.uploads.actual_histories.missing_or_invalid"))
    end

    scenario "when the file cannot be parsed" do
      file_content =
        <<~CSV
          invalid;csv;content
        CSV

      visit new_report_uploads_actual_history_path(report)
      upload_fixture(file_content)

      expect(page).to have_content(t("actions.uploads.actual_histories.missing_or_invalid"))
    end
  end

  context "as a delvivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }
    let(:report) { create(:report, organisation: beis_user.organisation) }

    before { authenticate!(user: delivery_partner_user) }

    scenario "they cannot see the actuals history upload interface" do
      report = create(:report)

      visit report_actuals_path(report)

      expect(page).not_to have_content(t("actions.uploads.actual_histories.new_upload"))
    end
  end

  def upload_fixture(content)
    file = Tempfile.new("actuals.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[actual_csv_file]", file.path
    click_button t("actions.uploads.actual_histories.upload.button")

    file.unlink
  end
end
