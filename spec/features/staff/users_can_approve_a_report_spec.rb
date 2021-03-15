RSpec.feature "Users can approve reports" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:organisation) { create(:organisation, users: create_list(:delivery_partner_user, 3)) }

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

      expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count)

      organisation.users.each do |user|
        expect(user).to be_sent_email.with_subject(t("mailer.report.approved.subject", application_name: t("app.title")))
      end
    end

    scenario "a new report is created for the delivery partner and level A activity" do
      organisation = create(:delivery_partner_organisation)
      fund = create(:fund_activity)
      _approved_report = create(:report, state: :approved, organisation: organisation, fund: fund)
      report = create(:report, state: :in_review, organisation: organisation, fund: fund)

      travel_to Date.parse("2019-7-1") do
        visit report_path(report)
        click_link t("action.report.approve.button")
        click_button t("action.report.approve.confirm.button")

        expect(report.reload.state).to eql "approved"

        expect(Report.where(state: :inactive, organisation: report.organisation, fund: report.fund).count).to eql 1

        new_report = Report.where(state: :inactive, organisation: report.organisation, fund: report.fund).first

        visit reports_path

        within "##{new_report.id}" do
          expect(page).to have_content new_report.organisation.name
          expect(page).to have_content new_report.fund.title
          expect(page).to have_content "Q2 2019-2020"
        end
      end
    end

    context "when the report is already approved" do
      scenario "it cannot be approved" do
        report = create(:report, state: :approved)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.approve.button")
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
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
