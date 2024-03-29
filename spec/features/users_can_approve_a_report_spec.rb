RSpec.feature "Users can approve reports" do
  context "signed in as a BEIS user" do
    let!(:beis_user) { create(:beis_user) }
    let(:organisation) {
      create(
        :partner_organisation,
        beis_organisation_reference: "AMS",
        users: create_list(:partner_organisation_user, 3)
      )
    }

    let(:upload) do
      OpenStruct.new(
        timestamped_filename: "filename-20231117173100.csv"
      )
    end
    let(:uploader) { instance_double(Export::S3Uploader, upload: upload) }

    before do
      authenticate!(user: beis_user)
    end

    after { logout }

    scenario "they can mark a report as approved" do
      allow(Export::S3Uploader).to receive(:new).and_return(uploader)

      # Given we have a report for FQ1 2023-2024 for AMS
      report = create(:report, :for_gcrf, financial_quarter: 1, financial_year: 2023, state: :qa_completed, organisation: organisation)

      # When we approve the report
      perform_enqueued_jobs do
        visit report_path(report)
        click_link t("action.report.approve.button")
        click_button t("action.report.approve.confirm.button")
      end

      # Then we expect the report to be marked as approved
      expect(page).to have_content "approved"
      expect(report.reload.state).to eql "approved"

      # And we expect the BEIS team and the partner org users to receive an "approved" email
      expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count + 1)

      expect(beis_user).to have_received_email.with_subject(t("mailer.report.approved.service_owner.subject", application_name: t("app.title"), environment_name: nil))

      organisation.users.each do |user|
        expect(user).to have_received_email.with_subject(t("mailer.report.approved.partner_organisation.subject", application_name: t("app.title"), environment_name: nil))
      end

      # And we expect the report CSV to have been uploaded and associated with the report
      expect(report.export_filename).to match(upload.timestamped_filename)
    end

    context "when the report is already approved" do
      scenario "it cannot be approved" do
        report = create(:report, :approved)

        visit report_path(report)

        within("#main-content") do
          expect(page).not_to have_link t("action.report.approve.button")
        end
      end
    end
  end

  context "signed in as a partner organisation user" do
    let(:partner_org_user) { create(:partner_organisation_user) }

    before do
      authenticate!(user: partner_org_user)
    end

    after { logout }

    scenario "they cannot mark a report as approved" do
      report = create(:report, state: :in_review)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.approve.button")

      visit edit_report_state_path(report)

      expect(page).to have_http_status(:unauthorized)
    end
  end
end
