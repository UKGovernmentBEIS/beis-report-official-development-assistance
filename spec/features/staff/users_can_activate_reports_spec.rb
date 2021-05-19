RSpec.feature "Users can activate reports" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:organisation) { create(:delivery_partner_organisation, users: build_list(:administrator, 3)) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can activate a report" do
      perform_enqueued_jobs do
        report = create(:report, state: :inactive, organisation: organisation)

        visit report_path(report)
        click_link t("action.report.activate.button")
        click_button t("action.report.activate.confirm.button")

        expect(page).to have_content "complete"
        expect(report.reload.state).to eql "active"

        expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count)

        organisation.users.each do |user|
          expect(user).to have_received_email.with_subject(t("mailer.report.activated.subject", application_name: t("app.title")))
        end
      end
    end

    scenario "they see a warning when the report is not valid i.e. has no description" do
      organisation = create(:delivery_partner_organisation)
      fund = create(:fund_activity)
      report = Report.new(organisation: organisation, fund: fund)
      report.save(validate: false)

      visit report_path(report)
      click_link t("action.report.activate.button")
      click_button t("action.report.activate.confirm.button")

      expect(page).to have_content t("action.report.activate.failure")
    end

    context "when the report is already active" do
      scenario "it cannot be activated again" do
        report = create(:report, state: :active)

        visit report_path(report)

        expect(page).not_to have_link "Activate report"

        visit edit_report_state_path(report)

        expect(page.status_code).to eql 401
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they cannot activate a report" do
      report = create(:report, state: :inactive)

      visit report_path(report)

      expect(page).not_to have_link "Activate report"

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
