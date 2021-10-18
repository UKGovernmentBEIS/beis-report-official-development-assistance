RSpec.feature "Users can view adjustments (irrespective of report state)" do
  let(:organisation) { create(:delivery_partner_organisation) }

  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:activity) { create(:project_activity, organisation: organisation) }

  before { authenticate!(user: user) }

  scenario "can view adjustments for an activity" do
    given_an_active_report_exists
    and_an_adjustment_exists
    and_the_report_is_no_longer_editable
    and_i_am_looking_at_the_activity_financials_tab

    then_i_expect_to_see_the_adjustment
  end

  def given_an_active_report_exists
    create(
      :report,
      :active,
      fund: activity.associated_fund,
      organisation: activity.organisation,
      financial_quarter: 1,
      financial_year: 2021
    )
  end

  def and_an_adjustment_exists
    create(
      :adjustment,
      :actual,
      parent_activity: activity,
      value: "100.01",
      financial_quarter: 4,
      financial_year: 2020,
      report: Report.editable_for_activity(activity)
    )
  end

  def and_the_report_is_no_longer_editable
    Report.editable_for_activity(activity).update_columns(state: "submitted")
  end

  def and_i_am_looking_at_the_activity_financials_tab
    visit organisation_activity_financials_path(
      organisation_id: activity.organisation.id,
      activity_id: activity.id
    )
  end

  def then_i_expect_to_see_the_adjustment
    adjustment = activity.adjustments.first

    fail "Expect activity to have an adjustment" unless adjustment
    within ".adjustments" do
      within "#adjustment_#{adjustment.id}" do
        expect(page).to have_css(".financial-period", text: "FQ4 2020-2021")
        expect(page).to have_css(".value", text: "£100.01")
        expect(page).to have_css(".type", text: "Actual")
        expect(page).to have_css(
          ".report a[href='#{report_path(adjustment.report)}']",
          text: "Report"
        )
      end
    end
  end
end
