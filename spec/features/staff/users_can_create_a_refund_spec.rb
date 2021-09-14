RSpec.feature "Users can create a refund" do
  let(:organisation) { create(:delivery_partner_organisation) }

  RSpec.shared_examples "create refunds" do
    before { authenticate!(user: user) }

    scenario "they can create a refund for an activity" do
      visit organisation_activity_financials_path(
        organisation_id: activity.organisation.id,
        activity_id: activity.id
      )

      click_on t("page_content.refund.button.create")
      then_i_see_that_my_refund_amount_will_be_negative

      fill_in "refund_form[value]", with: "100"
      choose "4", name: "refund_form[financial_quarter]"
      select "2019-2020", from: "refund_form[financial_year]"
      fill_in "refund_form[comment]", with: "Comment goes here"

      expect { click_on(t("default.button.submit")) }.to change(Refund, :count).by(1)

      expect(page).to have_content(t("action.refund.create.success"))

      newly_created_refund = Refund.last

      within "##{newly_created_refund.id}" do
        expect(page).to have_content("Q4 2019-2020")
        expect(page).to have_content("-£100")
      end
    end

    scenario "must supply the required information to create a refund" do
      given_i_am_on_the_new_refund_form
      and_i_submit_the_new_refund_form_incorrectly
      then_i_expect_to_see_how_i_need_to_correct_the_refund_form
    end
  end

  context "when logged in as a BEIS user" do
    include_examples "create refunds" do
      let(:user) { create(:beis_user) }
      let(:activity) { create(:programme_activity, :with_report) }
    end
  end

  context "when logged in as a delivery partner" do
    include_examples "create refunds" do
      let(:user) { create(:delivery_partner_user, organisation: organisation) }
      let(:activity) { create(:project_activity, :with_report, organisation: organisation) }
    end
  end

  def then_i_see_that_my_refund_amount_will_be_negative
    expect(page).to have_content("Your refund is stored as a negative amount")
  end

  def given_i_am_on_the_new_refund_form
    visit organisation_activity_financials_path(
      organisation_id: activity.organisation.id,
      activity_id: activity.id
    )
    click_on t("page_content.refund.button.create")
  end

  def and_i_submit_the_new_refund_form_incorrectly
    click_on(t("default.button.submit"))
  end

  def then_i_expect_to_see_how_i_need_to_correct_the_refund_form
    expect(page).to have_content("Select a financial quarter")
    expect(page).to have_content("Select a financial year")
    expect(page).to have_content("Enter a refund amount")
  end
end
