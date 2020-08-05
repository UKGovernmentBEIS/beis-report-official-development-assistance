RSpec.feature "Users can view a report" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
  let!(:report) { create(:report, organisation: delivery_partner_user.organisation, deadline: nil, description: "Legacy Submission", fund: activity.associated_fund) }

  context "as a BEIS user" do
    before do
      authenticate!(user: beis_user)
    end

    scenario "can view a report belonging to any delivery partner" do
      visit organisation_path(beis_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      expect(page).to have_content report.description
    end

    scenario "can download a CSV of the report" do
      visit organisation_path(beis_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      expect(page.response_headers["Content-Type"]).to include("text/csv")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{report.description}/)
    end

    scenario "the CSV download contains Activity data" do
      activity_presenter = ExportActivityToCsv.new(activity: activity).call
      visit organisation_path(beis_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      result = page.body

      expect(result).to include activity_presenter
    end
  end

  context "as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "can view their own report" do
      visit organisation_path(delivery_partner_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      expect(page).to have_content report.description
    end

    scenario "cannot view a report belonging to another delivery partner" do
      another_report = create(:report, organisation: create(:organisation))

      visit organisation_path(delivery_partner_user.organisation)

      expect(page).to_not have_content another_report.description
    end

    scenario "can download a CSV of their own report" do
      visit organisation_path(delivery_partner_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      expect(page.response_headers["Content-Type"]).to include("text/csv")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{report.description}/)
    end

    scenario "the CSV download contains Activity data" do
      activity_presenter = ExportActivityToCsv.new(activity: activity).call
      visit organisation_path(delivery_partner_user.organisation)

      within "##{report.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      result = page.body

      expect(result).to include activity_presenter
    end
  end
end
