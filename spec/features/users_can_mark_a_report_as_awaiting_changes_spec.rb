RSpec.feature "Users can move reports into awaiting changes & view reports awaiting changes" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:organisation) { create(:partner_organisation, users: create_list(:partner_organisation_user, 3)) }

    before do
      authenticate!(user: beis_user)
    end

    after { logout }

    context "when the report is in review" do
      scenario "they can mark a report as awaiting changes" do
        report = create(:report, state: :in_review, organisation: organisation)

        perform_enqueued_jobs do
          visit report_path(report)
          click_link t("action.report.request_changes.button")
          click_button t("default.button.confirm")
        end

        expect(page).to have_content "awaiting changes"
        expect(report.reload.state).to eql "awaiting_changes"

        expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count)

        organisation.users.each do |user|
          expect(user).to have_received_email.with_subject(t("mailer.report.awaiting_changes.subject", application_name: t("app.title"), environment_name: nil))
        end
      end
    end

    context "when the report is QA completed" do
      scenario "they can mark a report as awaiting changes" do
        report = create(:report, state: :qa_completed, organisation: organisation)

        perform_enqueued_jobs do
          visit report_path(report)
          click_link t("action.report.request_changes.button")
          click_button t("default.button.confirm")
        end

        expect(page).to have_content "awaiting changes"
        expect(report.reload.state).to eql "awaiting_changes"

        expect(ActionMailer::Base.deliveries.count).to eq(organisation.users.count)

        organisation.users.each do |user|
          expect(user).to have_received_email.with_subject(t("mailer.report.awaiting_changes.subject", application_name: t("app.title"), environment_name: nil))
        end
      end
    end

    context "when the report is already awaiting changes" do
      scenario "it cannot be set in review" do
        report = create(:report, state: :awaiting_changes)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.request_changes.button")
      end
    end
  end

  context "signed in as a partner organisation user" do
    let(:partner_org_user) { create(:partner_organisation_user) }

    before do
      authenticate!(user: partner_org_user)
    end

    after { logout }

    scenario "they cannot mark a report as in awaiting changes" do
      report = create(:report, state: :in_review, organisation: partner_org_user.organisation)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.request_changes.button")
    end
  end
end
