RSpec.feature "Users can view reports" do
  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can view all active reports for all organisations" do
      first_report = create(:report, :active)
      second_report = create(:report, :active)

      visit reports_path

      expect(page).to have_content t("page_title.report.index")
      expect(page).to have_content first_report.description
      expect(page).to have_content second_report.description
    end

    scenario "they see the name of the associated organisation in the table" do
      report = create(:report)

      visit reports_path

      expect(page).to have_content report.organisation.name
    end

    scenario "they see the financial quarter the of the report" do
      travel_to(Date.parse("1 Jan 2020")) do
        _report = create(:report, :active)

        visit reports_path

        expect(page).to have_content "Q4 2019-2020"
      end
    end

    scenario "they can view all inactive reports for all organisations" do
      reports = create_list(:report, 2)
      visit reports_path

      expect(page).to have_content t("page_title.report.index")
      expect(page).to have_content reports.first.description
      expect(page).to have_content reports.last.description
    end

    scenario "they can view submitted reports for all organisations" do
      reports = create_list(:report, 2)
      visit reports_path

      expect(page).to have_content reports.first.description
      expect(page).to have_content reports.last.description
    end

    scenario "can view a report belonging to any delivery partner" do
      report = create(:report, :active)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      expect(page).to have_content report.description
    end

    scenario "can download a CSV of the report" do
      report = create(:report, :active, description: "Legacy Report")

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      click_on t("action.report.download.button")

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/Legacy%20Report/)
    end

    context "when there are no reports in a given state" do
      scenario "an empty state is shown" do
        visit reports_path

        expect(page).to have_content t("table.body.report.no_reports")
      end
    end
  end

  context "as a delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    context "when there is an active report" do
      scenario "they can view reports for their own organisation" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)
        other_organisation_report = create(:report, :active)

        visit reports_path

        expect(page).to have_content t("page_title.report.index")
        expect(page).to have_content report.description
        expect(page).not_to have_content other_organisation_report.description
      end

      scenario "can view their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.description
      end

      scenario "the report shows the total forecasted and actual spend and the variance" do
        quarter_one_2019 = Date.parse("2019-4-1")
        quarter_two_2019 = Date.parse("2019-7-1")

        activity = create(:project_activity, organisation: delivery_partner_user.organisation)

        report = create(:report, :active, organisation: delivery_partner_user.organisation, fund: activity.associated_fund, financial_quarter: 1, financial_year: 2019, created_at: quarter_one_2019)
        report_presenter = ReportPresenter.new(report)

        _forecasted_value = create(:planned_disbursement, parent_activity: activity, period_start_date: quarter_one_2019, value: 1000)
        _actual_value = create(:transaction, parent_activity: activity, report: report, date: quarter_one_2019, value: 1100)

        travel_to quarter_two_2019 do
          visit reports_path
          within "##{report.id}" do
            click_on t("default.link.show")
          end

          expect(page).to have_content t("table.header.activity.identifier")
          expect(page).to have_content t("table.header.activity.forecasted_spend_for_quarter", financial_quarter_and_year: report_presenter.financial_quarter_and_year)
          within "##{activity.id}" do
            expect(page).to have_content "1000.00"
            expect(page).to have_content "1100.00"
            expect(page).to have_content "100.00"
            expect(page).to have_link t("default.link.view"), href: organisation_activity_path(activity.organisation, activity)
          end
        end
      end

      scenario "they can view their own submitted reports" do
        report = create(:report, state: :submitted, organisation: delivery_partner_user.organisation)

        visit reports_path

        expect(page).to have_content report.description
      end

      scenario "they do not see the name of the associated organisation" do
        report = create(:report)

        visit reports_path

        expect(page).not_to have_content report.organisation.name
      end

      scenario "cannot view a report belonging to another delivery partner" do
        another_report = create(:report, organisation: create(:organisation))

        visit report_path(another_report)

        expect(page).to have_http_status(401)
      end

      scenario "can download a CSV of their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation, description: "Legacy Report")

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        click_on t("action.report.download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        header = page.response_headers["Content-Disposition"]
        expect(header).to match(/Legacy%20Report/)
      end
    end

    context "when there are reports awaiting changes" do
      scenario "they see their own reports which are awaiting changes" do
        report = create(:report, organisation: delivery_partner_user.organisation, state: :awaiting_changes)

        visit reports_path

        expect(page).to have_content t("table.title.report.awaiting_changes")
        expect(page).to have_content report.description
      end
    end

    context "when there are approved reports" do
      scenario "they see their own reports which are approved" do
        report = create(:report, organisation: delivery_partner_user.organisation, state: :approved)

        visit reports_path

        expect(page).to have_content t("table.title.report.approved")
        expect(page).to have_content report.description
      end
    end
  end

  context "when there are no active reports" do
    scenario "they see no reports" do
      report = create(:report, state: :inactive)

      visit reports_path

      expect(page).not_to have_content report.description
    end
  end
end
