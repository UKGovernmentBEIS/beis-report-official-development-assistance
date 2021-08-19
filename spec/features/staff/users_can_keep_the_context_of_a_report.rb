RSpec.feature "Users can keep the context of a report" do
  let(:user) { create(:delivery_partner_user) }
  let(:report) { create(:report, :active, organisation: user.organisation) }
  let(:programme) { create(:programme_activity, :newton_funded, extending_organisation: user.organisation) }

  let!(:activity) { create(:project_activity, :newton_funded, originating_report: report, organisation: user.organisation, extending_organisation: user.organisation, parent: programme) }

  before do
    authenticate!(user: user)
    visit report_activities_path(report)
    click_on "View activity"
  end

  scenario "users can see the report breadcrumbs when accessing an activity from a report" do
    within ".govuk-breadcrumbs" do
      expect(page).to have_content "Home"
      expect(page).to have_content "Current Reports"
      expect(page).to have_content t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year)
      expect(page).to have_content activity.parent.title
      expect(page).to have_content activity.title
    end
  end

  scenario "users no longer see the report breadcrumbs after they navigate away from the activity" do
    visit organisation_activities_path(activity.organisation)

    click_link(href: organisation_activity_path(activity.organisation, activity))

    within ".govuk-breadcrumbs" do
      expect(page).to_not have_content "Current Reports"
      expect(page).to_not have_content t("page_title.report.show", report_fund: report.fund.source_fund.name, report_financial_quarter: report.financial_quarter_and_year)

      expect(page).to have_content "Home"
      expect(page).to have_content "Current activities"
      expect(page).to have_content activity.parent.title
      expect(page).to have_content activity.title
    end
  end
end
