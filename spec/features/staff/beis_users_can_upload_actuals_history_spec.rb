RSpec.feature "BEIS users upload actual history" do
  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:activity) { create(:project_activity) }
    let(:report) { create(:report, fund: activity.associated_fund, organisation: activity.organisation) }

    before { authenticate!(user: beis_user) }

    scenario "they can see the actuals history upload interface" do
      visit report_actuals_path(report)

      expect(page).to have_content(t("actions.uploads.actual_histories.new_upload"))
    end

    scenario "they can successfully upload a file" do
      file_content =
        <<~CSV
          RODA identifier,Financial quarter,Financial year,Value
          #{activity.roda_identifier},1,2021, 10000
        CSV

      visit new_report_uploads_actual_history_path(report)
      upload_fixture(file_content)

      expect(page).to have_content(t("actions.uploads.actual_histories.success"))
      expect(page).to have_content(activity.title)
      expect(page).to have_content(activity.roda_identifier)
      expect(page).to have_content("10,000")
      expect(page).to have_content("FQ1 2021-2022")
    end

    scenario "when the file is missing" do
      visit new_report_uploads_actual_history_path(report)
      click_button t("actions.uploads.actual_histories.upload.button")

      expect(page).to have_content(t("actions.uploads.actual_histories.missing"))
    end

    scenario "when the file cannot be parsed" do
      file_content =
        <<~CSV
          invalid;csv;content
        CSV

      visit new_report_uploads_actual_history_path(report)
      upload_fixture(file_content)

      expect(page).to have_content(t("actions.uploads.actual_histories.invalid"))
    end

    scenario "when the contents of the upload has errors" do
      file_content =
        <<~CSV
          RODA identifier,Financial quarter,Financial year,Value
          #{activity.roda_identifier},1,2021, Ten thousand pounds
        CSV

      visit new_report_uploads_actual_history_path(report)
      upload_fixture(file_content)

      expect(page).to have_content(t("actions.uploads.actual_histories.failed"))
      expect(page).to have_content("Value")
      expect(page).to have_content("2")
      expect(page).to have_content("Ten thousand pounds")
      expect(page).to have_content("Value must be a valid number")
    end
  end

  context "as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    let(:report) { create(:report, organisation: beis_user.organisation) }

    before { authenticate!(user: user) }

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
