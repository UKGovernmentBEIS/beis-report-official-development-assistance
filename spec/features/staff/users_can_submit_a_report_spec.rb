RSpec.feature "Users can submit a report" do
  context "as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they can submit a report" do
      report = create(:report, :active, organisation: delivery_partner_user.organisation)
      report_presenter = ReportPresenter.new(report)

      visit report_path(report)
      click_link I18n.t("action.report.submit.button")

      click_button "Confirm submission"

      expect(page).to have_content I18n.t("action.report.submit.complete.title")
      expect(page).to have_content I18n.t("action.report.submit.complete.title",
        report_description: report_presenter.description,
        report_financial_quater_and_year: report_presenter.financial_quarter_and_year)
    end

    scenario "a report submission is recorded in the audit log" do
      report = create(:report, state: :active, organisation: delivery_partner_user.organisation)
      PublicActivity.with_tracking do
        visit reports_path
        within "##{report.id}" do
          click_on I18n.t("default.link.view")
        end
        click_link I18n.t("action.report.submit.button")
        click_button I18n.t("action.report.confirm.button")

        auditable_events = PublicActivity::Activity.all
        expect(auditable_events.last.key).to include("report.submitted")
        expect(auditable_events.last.owner_id).to include delivery_partner_user.id
        expect(auditable_events.last.trackable_id).to include report.id
      end
    end

    scenario "they do not see the submit button for a submitted report" do
      report = create(:report, state: :submitted, organisation: delivery_partner_user.organisation)

      visit report_path(report)

      expect(page).not_to have_link I18n.t("action.report.submit.button"), href: report_submit_path(report)
    end
  end
end
