RSpec.feature "Users can view reports" do
  include HideFromBullet

  def expect_to_see_relevant_table_headings(headings: [])
    within "thead tr" do
      headings.each_with_index do |heading, heading_index|
        expect(page).to have_xpath("th[#{heading_index + 1}]", text: heading)
      end
    end
  end

  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    after { logout }

    def expect_to_see_a_table_of_reports_grouped_by_organisation(selector:, reports:, organisations:)
      within selector do
        expect(page.find_all("th[scope=rowgroup]").count).to eq(organisations.count)
        expect(page.find_all("tbody tr").count).to eq(reports.count)

        headings = ["Organisation", "Financial quarter"]
        headings.concat(["Deadline", "Status"]) if selector == "#current"
        headings.concat(["Fund (level A)", "Description"])

        expect_to_see_relevant_table_headings(headings: headings)

        organisations.each do |organisation|
          expect_to_see_grouped_rows_of_reports_for_an_organisation(
            organisation: organisation,
            expected_reports: reports.select { |r| r.organisation == organisation },
            selector: selector
          )
        end
      end
    end

    def expect_to_see_grouped_rows_of_reports_for_an_organisation(organisation:, expected_reports:, selector:)
      expected_heading_id = [organisation.id, selector[1, selector.length - 1]].join("-")

      expect(page).to have_selector("th[id='#{expected_heading_id}']")
      expect(page).to have_content organisation.name

      expected_reports.each do |report|
        within "##{report.id}" do
          expect(page).to have_content report.description
          expect(page).to have_content report.financial_quarter_and_year
        end
      end
    end

    scenario "they can see a list of all active and approved reports" do
      organisations = create_list(:partner_organisation, 2)

      unapproved_reports = [
        create_list(:report, 2, :active, organisation: organisations.first),
        create_list(:report, 3, :active, organisation: organisations.last),
        create_list(:report, 3, :awaiting_changes, organisation: organisations.first),
        create_list(:report, 2, :in_review, organisation: organisations.last)
      ].flatten

      approved_reports = [
        create_list(:report, 3, :approved, organisation: organisations.first),
        create_list(:report, 1, :approved, organisation: organisations.last)
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

    scenario "they can see a list of active and approved reports for a single organisation" do
      organisation = create(:partner_organisation)

      current = [
        create_list(:report, 2, :active, organisation: organisation),
        create_list(:report, 3, :awaiting_changes, organisation: organisation),
        create_list(:report, 2, :in_review, organisation: organisation)
      ].flatten

      approved = create_list(:report, 3, :approved, organisation: organisation)

      skip_bullet do
        visit organisation_reports_path(organisation)
      end

      expect(page).to have_content t("page_title.report.index")

      state_groups = ["current", "approved"]

      state_groups.each do |state_group|
        within "##{state_group}" do
          headings = ["Financial quarter"]
          headings.concat(["Deadline", "Status"]) if state_group == "current"
          headings.concat(["Fund (level A)", "Description"])

          expect_to_see_relevant_table_headings(headings: headings)

          reports = binding.local_variable_get(state_group)

          expect(page.find_all("tbody tr").count).to eq(reports.count)
        end
      end
    end

    scenario "can view a report belonging to any partner organisation" do
      report = create(:report, :active)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      expect(page).to have_content report.financial_quarter
      expect(page).to have_content report.fund.source_fund.name
    end

    describe "the report summary" do
      scenario "includes a summary" do
        report = create(:report, :for_gcrf, :active, organisation: build(:partner_organisation), is_oda: nil)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.description
        expect(page).to have_content l(report.deadline)
        expect(page).not_to have_content t("page_content.report.summary.editable.#{report.editable?}")
        expect(page).to have_content report.organisation.name

        expect(page).to have_content t("page_content.tab_content.summary.activities_added")
        expect(page).to have_content t("page_content.tab_content.summary.activities_updated")
        expect(page).to have_content t("page_content.tab_content.summary.actuals_total")
        expect(page).to have_content t("page_content.tab_content.summary.forecasts_total")
        expect(page).to have_content t("page_content.tab_content.summary.refunds_total")
      end

      context "when the report is for a 'generic' fund i.e. not ISPF" do
        scenario "the summary does not include the ODA state" do
          report = create(:report, :for_gcrf, :active, organisation: build(:partner_organisation), is_oda: nil)

          visit report_path(report)

          expect(page).not_to have_selector "#is-oda"
          expect(page).not_to have_content "ODA or Non-ODA"
        end
      end

      context "when the fund is ISPF" do
        scenario "the summary includes the ODA state" do
          report = create(:report, :for_ispf, :active, organisation: build(:partner_organisation), is_oda: true)

          visit report_path(report)

          within("#is-oda") do
            expect(page).to have_content "ODA or Non-ODA"
            expect(page).to have_content "ODA"
          end
        end
      end
    end

    scenario "the report includes a list of newly created and updated activities" do
      partner_organisation = create(:partner_organisation)
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund)
      project = create(:project_activity, parent: programme)
      report = create(:report, :active, fund: fund, organisation: partner_organisation, financial_quarter: 1, financial_year: 2021)

      new_activity = create(:third_party_project_activity, organisation: partner_organisation, parent: project, originating_report: report)
      updated_activity = create(:third_party_project_activity, organisation: partner_organisation, parent: project)

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

    context "when there is no report description" do
      scenario "the summary does not include the empty value" do
        report = create(:report, :active, organisation: build(:partner_organisation), description: nil)

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

    scenario "they see helpful guidance about and can download a CSV of a report" do
      report = create(:report, :active)

      visit reports_path

      within "##{report.id}" do
        click_on t("default.link.show")
      end

      expect(page).to have_content("Download a CSV file to review offline.")
      expect(page).to have_link("guidance in the help centre (opens in new tab)")

      click_link t("action.report.download.button")

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page).to have_http_status(:ok)
    end

    context "when the report has an export_filename" do
      scenario "the link to download the report is the download path instead of the show path" do
        report = create(:report, :approved, export_filename: "FQ4 2020-2021_GCRF_BA_report-20230111184653.csv")

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_link(t("action.report.download.button"), href: download_report_path(report))
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

    context "when there are no active reports" do
      scenario "they see an empty state on the current tab" do
        visit reports_path

        within("#current") do
          expect(page).to have_content t("table.body.report.no_current_reports")
        end
      end
    end

    context "when there are no approved reports" do
      scenario "they see an empty state on the approved tab" do
        visit reports_path

        within("#approved") do
          expect(page).to have_content t("table.body.report.no_approved_reports")
        end
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

      it "they canont be downloaded as CSV" do
        expect(page).not_to have_content "Download report as CSV file"
      end
    end

    scenario "they can view all comments made during a reporting period" do
      report = create(:report)

      activities = create_list(:project_activity, 2, organisation: report.organisation, source_fund_code: report.fund.source_fund_code)

      comments_for_report = [
        create_list(:comment, 3, commentable: activities[0], report: report),
        create_list(:comment, 1, commentable: activities[1], report: report)
      ].flatten

      page = ReportPage.new(report)
      page.visit_comments_page

      expect(page).to have_comments_grouped_by_activity(
        activities: activities,
        comments: comments_for_report
      )
      expect(page).to_not have_edit_buttons_for_comments(comments_for_report)
    end
  end

  context "as a partner organisation user" do
    let(:partner_org_user) { create(:partner_organisation_user) }

    def expect_to_see_a_table_of_reports(selector:, reports:)
      within selector do
        expect(page.find_all("tbody tr").count).to eq(reports.count)

        headings = ["Financial quarter"]
        headings.concat(["Deadline", "Status"]) if selector == "#current"
        headings.concat(["Fund (level A)", "Description"])
        headings << "Can edit?" if selector == "#current"

        expect_to_see_relevant_table_headings(headings: headings)

        reports.each do |report|
          within "##{report.id}" do
            expect(page).to have_content report.description
            expect(page).to have_content report.financial_quarter_and_year
          end
        end
      end
    end

    before do
      authenticate!(user: partner_org_user)
    end

    after { logout }

    scenario "they can see a list of all their active and approved reports" do
      reports_awaiting_changes = create_list(:report, 2, organisation: partner_org_user.organisation, state: :awaiting_changes)
      approved_reports = create_list(:report, 3, :approved, organisation: partner_org_user.organisation)

      visit reports_path

      expect(page).to have_content t("page_title.report.index")

      expect_to_see_a_table_of_reports(selector: "#current", reports: reports_awaiting_changes)
      expect_to_see_a_table_of_reports(selector: "#approved", reports: approved_reports)
    end

    context "when there is an active report" do
      scenario "can view their own report" do
        report = create(:report, :active, organisation: partner_org_user.organisation)

        visit reports_path

        expect_to_see_a_table_of_reports(selector: "#current", reports: [report])

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.financial_quarter
        expect(page).to have_content report.fund.source_fund.name
      end

      scenario "their own report includes a summary" do
        report = create(:report, :active, organisation: partner_org_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content report.description
        expect(page).to have_content l(report.deadline)
        expect(page).to have_content t("page_content.report.summary.editable.#{report.editable?}")
        expect(page).not_to have_content report.organisation.name

        expect(page).to have_content t("page_content.tab_content.summary.activities_added")
        expect(page).to have_content t("page_content.tab_content.summary.activities_updated")
        expect(page).to have_content t("page_content.tab_content.summary.actuals_total")
        expect(page).to have_content t("page_content.tab_content.summary.forecasts_total")
        expect(page).to have_content t("page_content.tab_content.summary.refunds_total")
      end

      scenario "the report shows the total forecasted and actual spend and the variance" do
        quarter_two_2019 = Date.parse("2019-7-1")

        activity = create(:project_activity, organisation: partner_org_user.organisation)
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

          click_on t("tabs.report.variance.heading")

          expect(page).to have_content t("table.header.activity.identifier")
          expect(page).to have_content t("table.header.activity.forecasted_spend")
          within "##{activity.id}" do
            expect(page).to have_content "£1,000.00"
            expect(page).to have_content "£1,100.00"
            expect(page).to have_content "£100.00"
          end

          within "tfoot tr:first-child td" do
            expect(page).to have_content "£100.00"
          end
        end
      end

      scenario "they see helpful content about uploading activities data on the activities tab" do
        report = create(:report, :active, organisation: partner_org_user.organisation)

        visit report_activities_path(report)

        expect(page).to have_text("Ensure you use the correct template when uploading activities data.")
        expect(page).to have_text("Large numbers of activities can be added via the activities upload.")
        expect(page).to have_text("For guidance on uploading activities data, see the")
        expect(page).to have_text("To get implementing organisation names, you can refer to the")
        expect(page).to have_link(
          "Upload activity data",
          href: new_report_activities_upload_path(report)
        )
        expect(page).to have_link(
          "guidance in the help centre (opens in new tab)",
          href: "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005510061-Understanding-the-Bulk-Upload-Functionality-to-Report-your-Data"
        )
        expect(page).to have_link(
          "Implementing organisations section (opens in new tab)",
          href: organisations_path
        )
      end

      scenario "they see helpful content about uploading actuals spend data and a link to the template on the actuals tab" do
        report = create(:report, :active, organisation: partner_org_user.organisation)

        visit report_actuals_path(report)

        expect(page).to have_text("Ensure you use the correct template (available below) when uploading the actuals and refunds.")
        expect(page).to have_text("Large numbers of actuals and refunds can be added via the actuals upload.")
        expect(page).to have_text("For guidance on uploading actuals and refunds, see")
        expect(page).to have_text("If you need to upload comments about why there are no actuals/refunds, add an activity comment rather than uploading a blank actuals template.")
        expect(page).to have_link(
          "Download actuals and refunds data template",
          href: report_actuals_upload_path(report, format: :csv)
        )
        expect(page).to have_link(
          "guidance in the help centre (opens in new tab)",
          href: "https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005601882-Downloading-the-Actuals-Template-in-order-to-Bulk-Upload"
        )
      end

      scenario "they can view and edit budgets in a report" do
        activity = create(:project_activity, organisation: partner_org_user.organisation)
        report = create(:report, :active, organisation: partner_org_user.organisation, fund: activity.associated_fund)
        budget = create(:budget, report: report, parent_activity: activity)

        visit report_budgets_path(report)

        within "##{budget.id}" do
          expect(page).to have_content budget.parent_activity.roda_identifier
          expect(page).to have_content budget.value
          expect(page).to have_link t("default.link.edit"), href: edit_activity_budget_path(budget.parent_activity, budget)
        end
      end

      scenario "they can view their own submitted reports" do
        report = create(:report, state: :submitted, organisation: partner_org_user.organisation)

        visit reports_path

        expect(page).to have_content report.description
      end

      scenario "they do not see the name of the associated organisation" do
        report = create(:report)

        visit reports_path

        expect(page).not_to have_content report.organisation.name
      end

      scenario "cannot view a report belonging to another partner organisation" do
        another_report = create(:report, organisation: create(:partner_organisation))

        visit report_path(another_report)

        expect(page).to have_http_status(:unauthorized)
      end

      scenario "they see helpful guidance about and can download a CSV of their own report" do
        report = create(:report, :active, organisation: partner_org_user.organisation)

        visit reports_path
        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_content("Download a CSV file to review offline.")
        expect(page).to have_link("guidance in the help centre (opens in new tab)")

        click_link t("action.report.download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        expect(page).to have_http_status(:ok)
      end
    end

    context "when the report has an export_filename" do
      scenario "the link to download the report is the download path instead of the show path" do
        report = create(:report, :approved, export_filename: "FQ4 2020-2021_GCRF_BA_report-20230111184653.csv", organisation: partner_org_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on t("default.link.show")
        end

        expect(page).to have_link(t("action.report.download.button"), href: download_report_path(report))
      end
    end

    scenario "they can view all comments made during a reporting period" do
      report = create(:report, :active, organisation: partner_org_user.organisation, fund: create(:fund_activity, :newton))
      activities = create_list(:project_activity, 2, :newton_funded, organisation: partner_org_user.organisation)

      activity_comments = [
        create_list(:comment, 3, commentable: activities[0], report: report, owner: partner_org_user),
        create_list(:comment, 1, commentable: activities[1], report: report, owner: partner_org_user)
      ].flatten

      actual_comments = [
        create_list(:comment, 1, commentable: create(:actual, parent_activity: activities[0]), report: report),
        create_list(:comment, 1, commentable: create(:actual, parent_activity: activities[1]), report: report)
      ].flatten

      refund_comments = [
        create_list(:comment, 2, commentable: create(:refund, parent_activity: activities[0]), report: report),
        create_list(:comment, 1, commentable: create(:refund, parent_activity: activities[1]), report: report)
      ].flatten

      adjustment_comments = create_list(:comment, 2, commentable: create(:adjustment, parent_activity: activities[0]), report: report)

      comments_for_report = activity_comments + actual_comments + refund_comments + adjustment_comments

      page = ReportPage.new(report)
      page.visit_comments_page

      expect(page).to have_comments_grouped_by_activity(
        activities: activities,
        comments: comments_for_report
      )
      expect(page).to have_edit_buttons_for_comments(activity_comments)
      expect(page).to_not have_edit_buttons_for_comments(adjustment_comments)
      expect(page).to_not have_edit_buttons_for_comments(comments_for_report)
    end

    context "when there are no active reports" do
      scenario "they see an empty state on the current tab" do
        report = create(:report, :approved, organisation: partner_org_user.organisation)

        visit reports_path

        within("#current") do
          expect(page).not_to have_content report.description
          expect(page).to have_content t("table.body.report.no_current_reports")
        end
      end
    end

    context "when there are no approved reports" do
      scenario "they see an empty state on the approved tab" do
        report = create(:report, organisation: partner_org_user.organisation)

        visit reports_path

        within("#approved") do
          expect(page).not_to have_content report.description
          expect(page).to have_content t("table.body.report.no_approved_reports")
        end
      end
    end
  end
end
