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

      expect(page).to have_content I18n.t("page_title.report.index")
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

      expect(page).to have_content I18n.t("page_title.report.index")
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
        click_on I18n.t("default.link.show")
      end

      expect(page).to have_content report.description
    end

    scenario "can download a CSV of the report" do
      report = create(:report, :active, description: "Legacy Report")

      visit reports_path

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("action.report.download.button")

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/Legacy%20Report/)
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

        expect(page).to have_content I18n.t("page_title.report.index")
        expect(page).to have_content report.description
        expect(page).not_to have_content other_organisation_report.description
      end

      scenario "can view their own report" do
        report = create(:report, :active, organisation: delivery_partner_user.organisation)

        visit reports_path

        within "##{report.id}" do
          click_on I18n.t("default.link.show")
        end

        expect(page).to have_content report.description
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
          click_on I18n.t("default.link.show")
        end

        click_on I18n.t("action.report.download.button")

        expect(page.response_headers["Content-Type"]).to include("text/csv")

        expect(page.response_headers["Content-Type"]).to include("text/csv")
        header = page.response_headers["Content-Disposition"]
        expect(header).to match(/Legacy%20Report/)
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
