RSpec.feature "Users can view reports" do
  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    def expect_to_see_a_table_of_reports_grouped_by_organisation(selector:, reports:, organisations:)
      within selector do
        expect(page.find_all("th[scope=rowgroup]").count).to eq(organisations.count)
        expect(page.find_all("tbody tr").count).to eq(reports.count)

        organisations.each do |organisation|
          expect_to_see_grouped_rows_of_reports_for_an_organisation(
            organisation: organisation,
            expected_reports: reports.select { |r| r.organisation == organisation }
          )
        end
      end
    end

    def expect_to_see_grouped_rows_of_reports_for_an_organisation(organisation:, expected_reports:)
      expect(page).to have_selector("th[id='#{organisation.id}']")
      expect(page).to have_content organisation.name

      expected_reports.each do |report|
        within "##{report.id}" do
          expect(page).to have_content report.description
          expect(page).to have_content report.financial_quarter_and_year
        end
      end
    end

    scenario "they can see a list of all active and approved reports" do
      organisations = create_list(:delivery_partner_organisation, 2)

      unapproved_reports = [
        create_list(:report, 2, :active, organisation: organisations.first),
        create_list(:report, 3, :active, organisation: organisations.last),
        create_list(:report, 3, :inactive, organisation: organisations.first),
        create_list(:report, 2, :inactive, organisation: organisations.last),
      ].flatten

      approved_reports = [
        create_list(:report, 3, :approved, organisation: organisations.first),
        create_list(:report, 1, :approved, organisation: organisations.last),
      ].flatten

      visit reports_path

      expect(page).to have_content t("page_title.report.index")

      expect_to_see_a_table_of_reports_grouped_by_organisation(
        selector: "#current",
        reports: unapproved_reports,
        organisations: organisations
      )

      expect_to_see_a_table_of_reports_grouped_by_organisation(
        selector: "#approved",
        reports: approved_reports,
        organisations: organisations
      )
    end

    scenario "can view a report belonging to any delivery partner" do
      report = create(:report, :active)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      expect(page).to have_content report.financial_quarter
      expect(page).to have_content report.fund.source_fund.name
    end

    scenario "the report includes a summary" do
      report = create(:report, :active, organisation: build(:delivery_partner_organisation))

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      expect(page).to have_content report.description
      expect(page).to have_content l(report.deadline)
      expect(page).not_to have_content t("page_content.report.summary.editable.#{report.editable?}")
      expect(page).to have_content report.organisation.name
    end

    scenario "the report includes a list of newly created and updated activities" do
      delivery_partner_organisation = create(:delivery_partner_organisation)
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund)
      project = create(:project_activity, parent: programme)
      report = create(:report, :active, fund: fund, organisation: delivery_partner_organisation, financial_quarter: 1, financial_year: 2021)

      new_activity = create(:third_party_project_activity, organisation: delivery_partner_organisation, parent: project, originating_report: report)
      updated_activity = create(:third_party_project_activity, organisation: delivery_partner_organisation, parent: project)

      _history_event = create(:historical_event, activity: updated_activity, report: report)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      within ".govuk-tabs" do
        click_on "Activities"
      end

      expect(page).to have_content new_activity.title
      expect(page).to have_content updated_activity.title
    end

    context "when there is no report descripiton" do
      scenario "the summary does not include the empty value" do
        report = create(:report, :active, organisation: build(:delivery_partner_organisation), description: nil)

        visit report_path(report.id)

        expect(page).not_to have_content t("form.label.report.description")
      end
    end

    scenario "they can view budgets in a report" do
      report = create(:report, :active)
      budget = create(:budget, report: report)

      visit report_budgets_path(report)

      within "##{budget.id}" do
        expect(page).to have_content budget.parent_activity.roda_identifier
        expect(page).to have_content budget.value
      end
    end

    scenario "can download a CSV of the report" do
      report = create(:report, :active)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      click_on t("action.report.download.button")

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{ERB::Util.url_encode("#{report.organisation.beis_organisation_reference}-report.csv")}\z/)
    end

    scenario "can download a spending breakdown CSV of the report" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund)
      dp_org = create(:delivery_partner_organisation)
      project = create(:project_activity, organisation: dp_org, parent: programme)
      report = create(:report, :active, organisation: dp_org, fund: programme.parent)
      create(:actual, report: report, parent_activity: project)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      click_on t("action.report.spending_download.button")

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{ERB::Util.url_encode("#{report.organisation.beis_organisation_reference}-report.csv")}\z/)

      download = CSV.parse(page.body)
      expected_row = ActivitySpendingBreakdown.new(report: report, activity: project).values
      expect(download.to_a).to include(expected_row)
    end

    context "when they download a CSV for all reports" do
      let!(:programme) { create(:programme_activity) }
      scenario "reports are sorted by DP" do
        first_dp_org = create(:delivery_partner_organisation, name: "a-delivery-partner")
        create(:report, :active, organisation: first_dp_org, fund: programme.parent)
        create(:project_activity, organisation: first_dp_org, parent: programme, delivery_partner_identifier: "a-dp-01")

        second_dp_org = create(:delivery_partner_organisation, name: "b-delivery-partner")
        create(:report, :active, organisation: second_dp_org, fund: programme.parent)
        create(:project_activity, organisation: second_dp_org, parent: programme, delivery_partner_identifier: "b-dp-01")

        visit reports_path

        click_on t("action.report.download.reports")
        document = CSV.parse(page.body, headers: true)
        dp_id_column = document.map { |column| column["Delivery partner identifier"] }

        expect(dp_id_column).to eq(["a-dp-01", "b-dp-01"])
      end

      scenario "activities in the report are sorted by hierarchy level" do
        dp_org = create(:delivery_partner_organisation)
        create(:report, :submitted, organisation: dp_org, fund: programme.parent)
        project = create(:project_activity, organisation: dp_org, parent: programme)
        create(:third_party_project_activity, organisation: dp_org, parent: project)

        visit reports_path

        click_on t("action.report.download.reports")
        document = CSV.parse(page.body, headers: true)
        level_column = document.map { |column| column["Level"] }

        expect(level_column).to eq(["Project (level C)", "Third-party project (level D)"])
      end

      scenario "all relevant reports are included in the CSV file" do
        first_dp_org = create(:delivery_partner_organisation)
        create(:report, :in_review, organisation: first_dp_org, fund: programme.parent)
        first_dp_org_project = create(:project_activity, organisation: first_dp_org, parent: programme, delivery_partner_identifier: "first-dp-01")

        second_dp_org = create(:delivery_partner_organisation)
        create(:report, :awaiting_changes, organisation: second_dp_org, fund: programme.parent)
        second_dp_org_project = create(:project_activity, organisation: second_dp_org, parent: programme, delivery_partner_identifier: "second-dp-01")

        third_dp_org = create(:delivery_partner_organisation)
        create(:report, :approved, organisation: third_dp_org, fund: programme.parent)
        third_dp_org_project = create(:project_activity, organisation: third_dp_org, parent: programme, delivery_partner_identifier: "third-dp-01")

        visit reports_path

        click_on t("action.report.download.reports")
        document = CSV.parse(page.body, headers: true)
        dp_id_column = document.map { |column| column["Delivery partner identifier"] }

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        expect(page.response_headers["Content-Disposition"]).to match("-All-Reports.csv")

        expect(dp_id_column).to have_content(first_dp_org_project.delivery_partner_identifier)
        expect(dp_id_column).to have_content(second_dp_org_project.delivery_partner_identifier)
        expect(dp_id_column).not_to have_content(third_dp_org_project.delivery_partner_identifier)
      end

      scenario "they get an error if one or more reports are from a different quarter" do
        first_dp_org = create(:delivery_partner_organisation)
        create(:report, :active, organisation: first_dp_org, fund: programme.parent, financial_quarter: 1)
        create(:project_activity, organisation: first_dp_org, parent: programme)

        second_dp_org = create(:delivery_partner_organisation)
        create(:report, :active, organisation: second_dp_org, fund: programme.parent, financial_quarter: 2)
        create(:project_activity, organisation: second_dp_org, parent: programme)

        visit reports_path

        click_on t("action.report.download.reports")

        expect(page).to have_content t("action.report.download.failure")
      end
    end

    context "if the report description is empty" do
      scenario "the report csv has a filename made up of the fund name & report financial year & quarter" do
        report = create(:report, :active, description: "", financial_quarter: 4, financial_year: 2019)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        click_on t("action.report.download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        header = page.response_headers["Content-Disposition"]
        expect(header).to match(/#{ERB::Util.url_encode("FQ4 2019-2020")}/)
        expect(header).to match(/#{ERB::Util.url_encode(report.fund.roda_identifier)}/)
      end
    end

    context "when there are no reports in a given state" do
      scenario "an empty state is shown" do
        visit reports_path

        expect(page).to have_content t("table.body.report.no_reports")
      end
    end

    context "when there are legacy ingested reports" do
      let(:activity) { create(:project_activity) }
      let!(:report) { create(:report, :active, fund: activity.associated_fund, organisation: activity.organisation, financial_quarter: nil, financial_year: nil) }

      before do
        visit reports_path
        within "##{report.id}" do
          click_on t("default.link.show")
        end
      end

      it "they can be viewed" do
        expect(page).to have_content "Variance"

        visit report_budgets_path(report)

        expect(page).to have_content "Budgets"
      end

      it "they can be downloaded as CSV" do
        click_on "Download report as CSV file"
      end

      it "the spending breakdown can be downloaded" do
        click_on "Download spending breakdown as CSV file"
      end
    end
  end

  context "as a delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    def expect_to_see_a_table_of_reports(selector:, reports:)
      within selector do
        expect(page.find_all("tbody tr").count).to eq(reports.count)

        reports.each do |report|
          within "##{report.id}" do
            expect(page).to have_content report.description
            expect(page).to have_content report.financial_quarter_and_year
          end
        end
      end
    end

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they can see a list of all their active and approved reports" do
      reports_awaiting_changes = create_list(:report, 2, organisation: delivery_partner_user.organisation, state: :awaiting_changes)
      approved_reports = create_list(:report, 3, organisation: delivery_partner_user.organisation, state: :approved)

      visit reports_path

      expect(page).to have_content t("page_title.report.index")

      expect_to_see_a_table_of_reports(selector: "#current", reports: reports_awaiting_changes)
      expect_to_see_a_table_of_reports(selector: "#approved", reports: approved_reports)
    end

    context "when there is an active report" do
      scenario "can view their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        expect_to_see_a_table_of_reports(selector: "#current", reports: [report])

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.financial_quarter
        expect(page).to have_content report.fund.source_fund.name
      end

      scenario "their own report includes a summary" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.description
        expect(page).to have_content l(report.deadline)
        expect(page).to have_content t("page_content.report.summary.editable.#{report.editable?}")
        expect(page).not_to have_content report.organisation.name
      end

      scenario "the report shows the total forecasted and actual spend and the variance" do
        quarter_two_2019 = Date.parse("2019-7-1")

        activity = create(:project_activity, organisation: delivery_partner_user.organisation)
        reporting_cycle = ReportingCycle.new(activity, 4, 2018)
        forecast = ForecastHistory.new(activity, financial_quarter: 1, financial_year: 2019)

        reporting_cycle.tick
        forecast.set_value(1000)

        reporting_cycle.tick
        report = Report.for_activity(activity).in_historical_order.first

        report_quarter = report.own_financial_quarter
        _actual_value = create(:actual, parent_activity: activity, report: report, value: 1100, **report_quarter)

        travel_to quarter_two_2019 do
          visit reports_path
          within "##{report.id}" do
            click_on t("default.link.show")
          end

          click_on t("tabs.report.variance")

          expect(page).to have_content t("table.header.activity.identifier")
          expect(page).to have_content t("table.header.activity.forecasted_spend")
          within "##{activity.id}" do
            expect(page).to have_content "£1,000.00"
            expect(page).to have_content "£1,100.00"
            expect(page).to have_content "£100.00"
            expect(page).to have_link t("default.link.view"), href: organisation_activity_path(activity.organisation, activity)
          end

          within "tfoot tr:first-child td" do
            expect(page).to have_content "£100.00"
          end
        end
      end

      scenario "they see helpful content about uploading acutals spend data and a link to the template on the actuals tab" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit report_actuals_path(report)

        expect(page.html).to include t("tabs.actuals.upload.copy_html")
        expect(page).to have_link t("page_content.actuals.button.download_template"),
          href: report_transaction_upload_path(report, format: :csv)
        expect(page).to have_link "guidance in the help centre (opens in new tab)",
          href: "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005601882-Downloading-the-Actuals-Template-in-order-to-Bulk-Upload"
      end

      scenario "they can view and edit budgets in a report" do
        activity = create(:project_activity, organisation: delivery_partner_user.organisation)
        report = create(:report, :active, organisation: delivery_partner_user.organisation, fund: activity.associated_fund)
        budget = create(:budget, report: report, parent_activity: activity)

        visit report_budgets_path(report)

        within "##{budget.id}" do
          expect(page).to have_content budget.parent_activity.roda_identifier
          expect(page).to have_content budget.value
          expect(page).to have_link t("default.link.edit"), href: edit_activity_budget_path(budget.parent_activity, budget)
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
        another_report = create(:report, organisation: create(:delivery_partner_organisation))

        visit report_path(another_report)

        expect(page).to have_http_status(401)
      end

      scenario "can download a CSV of their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        click_on t("action.report.download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        header = page.response_headers["Content-Disposition"]
        expect(header).to match(ERB::Util.url_encode("#{report.organisation.beis_organisation_reference}-report.csv"))
      end

      scenario "can download a spending breakdown CSV of their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        click_on t("action.report.spending_download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        header = page.response_headers["Content-Disposition"]
        expect(header).to match(ERB::Util.url_encode("#{report.organisation.beis_organisation_reference}-report.csv"))
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
