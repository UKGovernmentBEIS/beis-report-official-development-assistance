RSpec.feature "Users can approve reports" do
  context "signed in as a BEIS user" do
    let!(:beis_user) { create(:beis_user) }
    let(:organisation) { create(:partner_organisation, users: create_list(:partner_organisation_user, 3)) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can mark a report as approved" do
      report = create(:report, state: :in_review, organisation: organisation)

      perform_enqueued_jobs do
        visit report_path(report)
        click_link t("action.report.approve.button")
        click_button t("action.report.approve.confirm.button")
      end

      expect(page).to have_content "approved"
      expect(report.reload.state).to eql "approved"

      expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count + 1)

      expect(beis_user).to have_received_email.with_subject(t("mailer.report.approved.service_owner.subject", application_name: t("app.title"), environment_name: nil))

      organisation.users.each do |user|
        expect(user).to have_received_email.with_subject(t("mailer.report.approved.partner_organisation.subject", application_name: t("app.title"), environment_name: nil))
      end
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

    scenario "they cannot mark a report as approved" do
      report = create(:report, state: :in_review)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.approve.button")

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
