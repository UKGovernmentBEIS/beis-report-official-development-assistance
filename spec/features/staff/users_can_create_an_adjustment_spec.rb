RSpec.feature "Users can create an adjustment (correcting spend in an approved report)" do
  let(:organisation) { create(:delivery_partner_organisation) }

  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:activity) { create(:project_activity, organisation: organisation) }

  before { authenticate!(user: user) }

  scenario "can create an adjustment for an activity" do
    given_an_active_report_exists
    and_i_am_looking_at_the_activity_financials_tab

    when_i_submit_the_new_adjustment_form_correctly
    then_i_expect_to_see_the_new_adjustment
    and_the_adjustment_should_not_appear_in_the_list_of_actuals
    and_i_can_drill_down_to_the_details_of_the_adjustment
    and_i_can_navigate_back_to_the_associated_activity_or_report
  end

  scenario "must supply the required information to create an adjustment" do
    given_an_active_report_exists
    and_i_am_looking_at_the_activity_financials_tab

    when_i_submit_the_new_adjustment_form_incorrectly
    then_i_expect_to_see_how_i_need_to_correct_the_form
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

  def and_i_am_looking_at_the_activity_financials_tab
    visit organisation_activity_financials_path(
      organisation_id: activity.organisation.id,
      activity_id: activity.id
    )
  end

  def when_i_submit_the_new_adjustment_form_correctly
    click_on t("page_content.adjustment.button.create")
    fill_in "adjustment_form[value]", with: "100.01"
    select "Actual", from: "adjustment_form[adjustment_type]"
    choose "2", name: "adjustment_form[financial_quarter]"
    select "2021-2022", from: "adjustment_form[financial_year]"
    fill_in "adjustment_form[comment]", with: "There was a typo in the original 'actual'"
    click_on(t("default.button.submit"))
  end

  def when_i_submit_the_new_adjustment_form_incorrectly
    click_on t("page_content.adjustment.button.create")
    click_on(t("default.button.submit"))
  end

  def then_i_expect_to_see_the_new_adjustment
    expect(page).to have_content(t("action.adjustment.create.success"))
    adjustment = activity.adjustments.first

    fail "Expect activity to have an adjustment" unless adjustment
    within ".adjustments" do
      within "#adjustment_#{adjustment.id}" do
        expect(page).to have_css(".financial-period", text: "FQ2 2021-2022")
        expect(page).to have_css(".value", text: "£100.01")
        expect(page).to have_css(".type", text: "Actual")
        expect(page).to have_css(
          ".report a[href='#{report_path(adjustment.report)}']",
          text: "Report"
        )
      end
    end
  end

  def and_the_adjustment_should_not_appear_in_the_list_of_actuals
    expect(page).not_to have_css(".transactions td", text: "£100.01")
  end

  def and_i_can_drill_down_to_the_details_of_the_adjustment
    within first(".adjustment") do
      click_on "View"
    end
    expect(page).to have_content(user.email)
    expect(page).to have_content("£100.01")
    expect(page).to have_content("Actual")
    expect(page).to have_content("FQ2 2021-2022")
    expect(page).to have_content("There was a typo in the original 'actual'")
  end

  def and_i_can_navigate_back_to_the_associated_activity_or_report
    expect(page).to have_link(
      "View",
      href: organisation_activity_financials_path(
        organisation_id: activity.organisation.id,
        activity_id: activity.id
      )
    )

    expect(page).to have_link(
      "View",
      href: report_path(activity.adjustments.first.report)
    )
  end

  def then_i_expect_to_see_how_i_need_to_correct_the_form
    expect(page).to have_content("Select a financial quarter")
    expect(page).to have_content("Select a financial year")
    expect(page).to have_content("Select the type of adjustment")
    expect(page).to have_content("Enter a comment explaining the adjustment")
    expect(page).to have_content("Enter an amount")
  end
end
