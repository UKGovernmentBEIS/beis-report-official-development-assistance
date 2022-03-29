RSpec.feature "Users can create a refund" do
  let(:organisation) { create(:delivery_partner_organisation) }

  RSpec.shared_examples "create refunds" do
    before { authenticate!(user: user) }

    scenario "they can create a refund for an activity" do
      given_i_am_on_the_new_refund_form
      then_i_see_that_my_refund_amount_will_be_negative
      and_i_submit_the_new_refund_form_correctly
      then_a_new_refund_should_be_created
      and_i_expect_to_see_that_a_new_refund_has_been_created
      and_new_historical_events_should_be_created
    end

    scenario "must supply the required information to create a refund" do
      given_i_am_on_the_new_refund_form
      and_i_submit_the_new_refund_form_incorrectly
      then_i_expect_to_see_how_i_need_to_correct_the_refund_form
      when_i_submit_the_new_refund_form_with_a_non_numeric_value
      then_i_should_see_that_my_value_was_non_numeric
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
    @refund_form = RefundsForm.create(activity: activity)
  end

  def and_i_submit_the_new_refund_form_incorrectly
    @refund_form.complete
  end

  def and_i_submit_the_new_refund_form_correctly
    @refund_form.complete(
      value: "100",
      financial_quarter: 4,
      financial_year: 2019,
      comment: "Comment goes here"
    )
  end

  def when_i_submit_the_new_refund_form_with_a_non_numeric_value
    @refund_form.complete(
      value: "I am not numerical",
      financial_quarter: 4,
      financial_year: 2019,
      comment: "Comment goes here"
    )
  end

  def then_i_expect_to_see_how_i_need_to_correct_the_refund_form
    expect(page).to have_content("Select a financial quarter")
    expect(page).to have_content("Select a financial year")
    expect(page).to have_content("Enter a refund amount")
  end

  def then_i_should_see_that_my_value_was_non_numeric
    expect(page).to have_content("Refund amount must be a valid number")
  end

  def then_a_new_refund_should_be_created
    expect(Refund.count).to eq(1)
  end

  def and_i_expect_to_see_that_a_new_refund_has_been_created
    expect(page).to have_content(t("action.refund.create.success"))

    newly_created_refund = Refund.last

    within "##{newly_created_refund.id}" do
      expect(page).to have_content(@refund_form.financial_quarter_and_year)
      expect(page).to have_content(@refund_form.value_with_currency)
    end
  end

  def and_new_historical_events_should_be_created
    historical_events = HistoricalEvent.where(trackable_id: Refund.last.id)

    expect(historical_events.count).to eq(4)
    expect(historical_event_for_value(historical_events, "value").new_value).to eq(@refund_form.value)
    expect(historical_event_for_value(historical_events, "financial_quarter").new_value).to eq(@refund_form.financial_quarter)
    expect(historical_event_for_value(historical_events, "financial_year").new_value).to eq(@refund_form.financial_year)
    expect(historical_event_for_value(historical_events, "comment").new_value).to eq(@refund_form.comment)
  end

  def historical_event_for_value(events, value)
    events.find { |e| e.value_changed == value }
  end
end
