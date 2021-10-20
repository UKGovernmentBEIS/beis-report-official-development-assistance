RSpec.feature "Users can submit a report" do
  context "as a Delivery partner user" do
    let!(:service_owner) { create(:beis_user) }
    let(:organisation) { create(:delivery_partner_organisation, users: create_list(:delivery_partner_user, 2)) }
    let(:delivery_partner_user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    context "when the report is active" do
      scenario "they can submit a report" do
        report = create(:report, organisation: delivery_partner_user.organisation)
        report_presenter = ReportPresenter.new(report)

        perform_enqueued_jobs do
          visit report_path(report)
          click_link t("action.report.submit.button")

          click_button t("action.report.submit.confirm.button")
        end

        expect(page).to have_content t("action.report.submit.complete.title",
          report_organisation: report.organisation.name,
          report_financial_quarter: report_presenter.financial_quarter_and_year)
        expect(report.reload.state).to eql "submitted"

        expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count + 1)

        expect(service_owner).to have_received_email.with_subject(t("mailer.report.submitted.service_owner.subject", application_name: t("app.title")))

        organisation.users.each do |user|
          expect(user).to have_received_email.with_subject(t("mailer.report.submitted.delivery_partner.subject", application_name: t("app.title")))
        end
      end
    end

    context "when the report is awaiting changes" do
      scenario "they can submit a report" do
        report = create(:report, :awaiting_changes, organisation: delivery_partner_user.organisation)
        report_presenter = ReportPresenter.new(report)

        visit report_path(report)
        click_link t("action.report.submit.button")

        click_button t("action.report.submit.confirm.button")

        expect(page).to have_content t("action.report.submit.complete.title",
          report_organisation: report.organisation.name,
          report_financial_quarter: report_presenter.financial_quarter_and_year)
        expect(report.reload.state).to eql "submitted"
      end
    end

    context "when the report is submitted" do
      scenario "they cannot submit a submitted report" do
        report = create(:report, state: :submitted, organisation: delivery_partner_user.organisation)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.submit.button"), href: edit_report_state_path(report)

        visit edit_report_state_path(report)

        expect(page.status_code).to eql 401
      end
    end
  end

  context "when signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they cannot submit a report" do
      report = create(:report, state: :active)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.submit.button"), href: edit_report_state_path(report)

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
