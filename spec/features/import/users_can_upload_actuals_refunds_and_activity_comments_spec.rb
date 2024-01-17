RSpec.feature "users can upload actuals, refunds and activity comments" do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }

  let!(:project) { create(:project_activity, :newton_funded, organisation: organisation) }
  let!(:another_project) { create(:project_activity, :newton_funded, organisation: organisation, parent: project.parent) }
  let!(:yet_another_project) { create(:project_activity, :newton_funded, organisation: organisation, parent: project.parent) }

  let!(:report) { create(:report, :active, fund: project.associated_fund, organisation: organisation) }

  before do
    authenticate!(user: user)
    visit report_actuals_path(report)
    click_link t("page_content.actuals.button.upload")

    allow(ROLLOUT).to receive(:active?).with(:use_new_activity_actual_refund_comment_importer).and_return(true)
  end

  context "when the import is successful" do
    let(:uploaded_csv) do
      csv_data = <<~CSV
        Activity RODA Identifier                | Financial Quarter | Financial Year | Actual Value | Refund Value | Comment
        #{project.roda_identifier}              | 1                 | 2020           | 20000        | 0            |
        #{another_project.roda_identifier}      | 1                 | 2020           | 0            | 30000        | Refund comment
        #{yet_another_project.roda_identifier}  | 1                 | 2020           | 0            | 0            | Activity comment
        #{project.roda_identifier}              | 1                 | 2020           | 0            | 0            |
      CSV
      upload_csv(csv_data)
    end

    it "shows the actuals and refunds that were imported" do
      attach_file "report[actual_csv]", uploaded_csv.path
      click_button t("action.actual.upload.button")

      expect(Actual.count).to be 1
      expect(Refund.count).to be 1

      expect(page).to have_text(t("action.actual.upload.success"))

      within("#actuals") do
        expect(page).to have_content(project.roda_identifier)
        expect(page).to have_content("£20,000.00")
      end

      within("#refunds") do
        expect(page).to have_content(another_project.roda_identifier)
        expect(page).to have_content("-£30,000.00")
      end

      within("#comments") do
        expect(page).to have_content(yet_another_project.roda_identifier)
        expect(page).to have_content("Activity comment")
      end

      within("#skipped") do
        expect(page).to have_content("5")
        expect(page).to have_content(project.roda_identifier)
      end
    end

    it "allows the user to see the activity comment" do
      attach_file "report[actual_csv]", uploaded_csv.path
      click_button t("action.actual.upload.button")
      visit report_comments_path(report)

      expect(page).to have_content("Activity comment")
      expect(page).to have_content(yet_another_project.roda_identifier)
    end
  end

  context "when the import is unsuccessful" do
    it "shows an error when the uploaded file does not contain the required headers" do
      csv_data = <<~CSV
        Incorrect Header           | Not correct header |
        #{project.roda_identifier} | 1                  |
      CSV
      uploaded_csv = upload_csv(csv_data)

      attach_file "report[actual_csv]", uploaded_csv.path
      click_button t("action.actual.upload.button")

      expect(page).to have_content("Invalid headers in the csv file")
    end

    it "shows the error when the uploaded actual is not valid" do
      csv_data = <<~CSV
        Activity RODA Identifier                | Financial Quarter | Financial Year | Actual Value | Refund Value | Comment
        #{project.roda_identifier}              | 1                 | 2020           | -20000        | 0            |
      CSV
      uploaded_csv = upload_csv(csv_data)

      attach_file "report[actual_csv]", uploaded_csv.path
      click_button t("action.actual.upload.button")

      expect(page).to have_content("Cannot be negative")
    end

    it "shows the error when the uploaded refund is not valid" do
      csv_data = <<~CSV
        Activity RODA Identifier                | Financial Quarter | Financial Year | Actual Value | Refund Value | Comment
        #{project.roda_identifier}              | 1                 | 2020           | 0            | -30000       |
      CSV
      uploaded_csv = upload_csv(csv_data)

      attach_file "report[actual_csv]", uploaded_csv.path
      click_button t("action.actual.upload.button")

      expect(page).to have_content("Refund must have a comment")
    end
  end

  def upload_csv(content)
    file = Tempfile.new("test.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close
    file
  end
end
