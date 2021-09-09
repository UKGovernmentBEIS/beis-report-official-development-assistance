RSpec.feature "Users can edit a refund" do
  let(:organisation) { create(:delivery_partner_organisation) }

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
        "value" => BigDecimal("100"),
      }).and change { refund.comment.reload.comment }.to("Comment goes here")

      expect(page).to have_content(t("action.refund.update.success"))
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

  context "when logged in as a delivery partner" do
    include_examples "edit refunds" do
      let(:user) { create(:delivery_partner_user, organisation: organisation) }
      let(:activity) { create(:project_activity, organisation: organisation) }
      let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }
    end
  end

  def then_i_see_the_refund_values_prefilled_as_expected
    expect(page).to have_field("refund_form[value]", with: "110.01")
    expect(page).to have_checked_field(
      "refund_form[financial_quarter]",
      with: refund.financial_quarter
    )
    page.has_css?(
      "#refund-form-financial-year-field option[value='#{refund.financial_year}'][selected='selected']"
    )
    expect(page).to have_field("refund_form[comment]", with: refund.comment.comment)
  end
end
