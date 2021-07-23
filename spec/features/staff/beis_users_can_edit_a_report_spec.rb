require "rails_helper"

RSpec.feature "BEIS users can edit a report" do
  context "Logged in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    before { travel_to DateTime.parse("2021-01-01") }
    after { travel_back }

    scenario "they can edit a Report to set the deadline" do
      user = create(:beis_user)
      authenticate!(user: user)
      report = create(:report)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "2021"

      click_on t("default.button.submit")

      expect(page).to have_content t("action.report.update.success")
      within "##{report.id}" do
        expect(page).to have_content("31 Jan 2021")
        click_on t("default.link.edit")
      end
      expect(page).to have_field("report[deadline(1i)]", with: "2021")
      expect(page).to have_field("report[deadline(2i)]", with: "1")
      expect(page).to have_field("report[deadline(3i)]", with: "31")
    end

    scenario "the deadline cannot be in the past" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "2001"

      click_on t("default.button.submit")

      expect(page).to_not have_content t("action.report.update.success")
      expect(page).to have_content t("activerecord.errors.models.report.attributes.deadline.not_in_past")
    end

    scenario "the deadline cannot be very far in the future" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.edit")
      end

      fill_in "report[deadline(3i)]", with: "31"
      fill_in "report[deadline(2i)]", with: "1"
      fill_in "report[deadline(1i)]", with: "200020"

      click_on t("default.button.submit")

      expect(page).to_not have_content t("action.report.update.success")
      expect(page).to have_content t("activerecord.errors.models.report.attributes.deadline.between", min: 10, max: 25)
    end

    scenario "they can edit a Report to change the description (Reporting Period)" do
      authenticate!(user: beis_user)
      report = create(:report)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.edit")
      end

      fill_in "report[description]", with: "Quarter 4 2020"

      click_on t("default.button.submit")

      expect(page).to have_content t("action.report.update.success")

      within "##{report.id}" do
        expect(page).to have_content("Quarter 4 2020")
      end
    end

    scenario "they see the organisation, level A activity and financial quarter for the report" do
      authenticate!(user: beis_user)
      report = create(:report)
      report_presenter = ReportPresenter.new(report)

      visit edit_report_path(report)

      expect(page).to have_content report_presenter.organisation.name
      expect(page).to have_content report_presenter.fund.title
      expect(page).to have_content report_presenter.financial_quarter_and_year
    end
  end

  context "Logged in as a Delivery Partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    scenario "they cannot edit a Report" do
      report = create(:report, state: :active, organisation: delivery_partner_user.organisation)

      authenticate!(user: delivery_partner_user)

      visit reports_path

      within "##{report.id}" do
        expect(page).to_not have_content(t("default.link.edit"))
      end
    end
  end
end
