require "rails_helper"

RSpec.feature "BEIS users can create a report" do
  let(:beis_user) { create(:beis_user) }
  let!(:newton_fund) { create(:fund_activity, :newton) }
  let!(:gcrf_fund) { create(:fund_activity, :gcrf) }
  let!(:partner_organisation) { create(:partner_organisation, name: "ACME Ltd") }

  before { travel_to DateTime.parse("2021-01-01") }

  after do
    travel_back
    logout
  end

  scenario "they can create a new report with all the required attributes" do
    given_i_am_a_logged_in_beis_user
    when_i_am_on_the_reports_page
    then_i_can_create_a_new_report
    and_the_report_is_active
  end

  context "when the feature flag hiding ISPF is enabled for BEIS users" do
    let!(:ispf_fund) { create(:fund_activity, :ispf) }

    before do
      allow(ROLLOUT).to receive(:active?).with(:ispf_fund_in_stealth_mode, beis_user).and_return(true)
    end

    scenario "they cannot create an ISPF report" do
      given_i_am_a_logged_in_beis_user
      when_i_am_on_the_new_report_page
      then_i_cannot_choose_ispf_as_the_fund
    end
  end

  def given_i_am_a_logged_in_beis_user
    authenticate!(user: beis_user)
  end

  def when_i_am_on_the_reports_page
    visit reports_path
  end

  def then_i_can_create_a_new_report
    click_on "Create a new report"

    choose "Q3"
    select "2018-2019", from: "Financial year"
    choose "Newton Fund"
    select "ACME Ltd", from: "Partner organisation"
    click_on "Submit"
    expect(page).to have_content("success")
  end

  def and_the_report_is_active
    within("#current") do
      expect(page).to have_content("ACME Ltd")
      expect(page).to have_content("FQ3 2018-2019")
      expect(page).to have_content("Active")
    end
  end

  def when_i_am_on_the_new_report_page
    visit new_report_path
  end

  def then_i_cannot_choose_ispf_as_the_fund
    expect(page).not_to have_content("International Science Partnerships Fund")
  end
end
