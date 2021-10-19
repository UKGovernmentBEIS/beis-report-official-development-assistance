require "rails_helper"

RSpec.feature "BEIS users can create a report" do
  let(:beis_user) { create(:beis_user) }
  let!(:newton_fund) { create(:fund_activity, :newton) }
  let!(:gcrf_fund) { create(:fund_activity, :gcrf) }
  let!(:delivery_partner_organisation) { create(:delivery_partner_organisation, name: "ACME Ltd") }

  before { travel_to DateTime.parse("2021-01-01") }
  after { travel_back }

  scenario "they can create a new report with all the required attributes" do
    given_i_am_a_logged_in_beis_user
    when_i_am_on_the_reports_page
    then_i_can_create_a_new_report
    and_the_report_is_active
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
    select "ACME Ltd", from: "Delivery partner organisation"
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
end
