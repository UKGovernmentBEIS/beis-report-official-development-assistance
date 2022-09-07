RSpec.feature "Users can edit a refund" do
  let(:organisation) { create(:partner_organisation) }

  RSpec.shared_examples "edit refunds" do
    let!(:refund) { create(:refund, parent_activity: activity, report: report) }

    before do
      authenticate!(user: user)

      visit organisation_activity_financials_path(
        organisation_id: activity.organisation.id,
        activity_id: activity.id
      )

      within "##{refund.id}" do
        click_on "Edit refund"
      end
      then_i_see_the_refund_values_prefilled_as_expected
      and_i_see_the_refund_value_field_with_a_negative_amount
    end

    scenario "they can edit a refund for an activity" do
      fill_in "refund_form[value]", with: "100"
      choose "4", name: "refund_form[financial_quarter]"
      select "2019-2020", from: "refund_form[financial_year]"
      fill_in "refund_form[comment]", with: "Comment goes here"

      expect {
        click_on(t("default.button.submit"))
      }.to change {
        refund.reload.attributes.slice("financial_year", "financial_quarter", "value")
      }.to({
        "financial_year" => 2019,
        "financial_quarter" => 4,
        "value" => BigDecimal("-100")
      }).and change { refund.comment.reload.body }.to("Comment goes here")

      expect(page).to have_content(t("action.refund.update.success"))

      and_the_refund_update_appears_in_the_change_history
    end

    scenario "they can delete a refund" do
      expect { click_on t("default.button.delete") }.to change(Refund, :count).by(-1)
    end
  end

  context "when logged in as a BEIS user" do
    include_examples "edit refunds" do
      let(:user) { create(:beis_user) }
      let(:activity) { create(:programme_activity) }
      let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }
    end
  end

  context "when logged in as a partner organisation user" do
    include_examples "edit refunds" do
      let(:user) { create(:partner_organisation_user, organisation: organisation) }
      let(:activity) { create(:project_activity, organisation: organisation) }
      let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }
    end
  end

  def then_i_see_the_refund_values_prefilled_as_expected
    expect(page).to have_checked_field(
      "refund_form[financial_quarter]",
      with: refund.financial_quarter
    )
    page.has_css?(
      "#refund-form-financial-year-field option[value='#{refund.financial_year}'][selected='selected']"
    )
    expect(page).to have_field("refund_form[comment]", with: refund.comment.body)
  end

  def and_i_see_the_refund_value_field_with_a_negative_amount
    expect(page).to have_field("refund_form[value]", with: "-110.01")
  end

  def and_the_refund_update_appears_in_the_change_history
    visit organisation_activity_historical_events_path(
      organisation_id: activity.organisation.id,
      activity_id: activity.id
    )
    within(".historical-events") do
      expect(page).to have_css(".refund .property", text: "value")
      expect(page).to have_css(".refund .previous-value", text: "")
      expect(page).to have_css(".refund .new-value", text: "-100.0")
      expect(page).to have_css(".refund .property", text: "comment")
      expect(page).to have_css(".refund .new-value", text: "Comment goes here")
      expect(page).to have_css(
        ".refund .report a[href='#{report_path(activity.refunds.first.report)}']",
        text: activity.refunds.first.report.financial_quarter_and_year
      )
    end
  end
end
