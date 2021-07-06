RSpec.feature "Users can view actuals in tab within a report" do
  context "as a Delivery Partner user" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: user)
    end

    def expect_to_see_a_table_of_transactions_grouped_by_activity(activities)
      expect(page).to have_content(
        t("page_content.tab_content.transactions.per_activity_heading")
      )

      fail "We expect some activities to be present" if activities.none?

      activities.each do |activity|
        within "#activity_#{activity.id}" do
          expect(page).to have_content(activity.title)
          expect(page).to have_content(activity.roda_identifier)

          fail "We expect some transactions to be present" if activity.transactions.none?

          within ".transactions" do
            activity.transactions.each do |transaction|
              expect(page).to have_content(transaction.value)
            end
          end
        end
      end
    end

    def expect_to_see_total_of_actual_amounts(activities)
      transaction_total = activities.map(&:transactions).flatten.sum(&:value)

      within ".totals" do
        expect(page).to have_content(
          ActionController::Base.helpers.number_to_currency(transaction_total, unit: "£")
        )
      end
    end

    scenario "the report contains an _actuals_ tab" do
      report = create(:report, state: :active, organisation: organisation, description: nil)

      programme = create(:programme_activity)
      project = create(:project_activity, organisation: organisation, parent: programme)

      activities = [
        create(:third_party_project_activity,
          organisation: organisation,
          parent: project).tap do |activity|
          create(:transaction, report: report, parent_activity: activity)
        end,
        create(:third_party_project_activity,
          organisation: organisation,
          parent: project).tap do |activity|
          create_list(:transaction, 3, report: report, parent_activity: activity)
        end,
      ]

      visit report_path(report.id)

      click_link t("tabs.report.transactions")

      expect(page).to have_content(t("page_content.tab_content.transactions.heading"))
      expect(page).to have_link(t("action.transaction.upload.link"))

      # guidance with 2 links
      expect(page).to have_content("This page shows all the actual spend you have reported in RODA since the last reporting quarter")
      expect(page).to have_link("uploading new actuals")
      expect(page).to have_link("uploading updates to activities")

      expect_to_see_a_table_of_transactions_grouped_by_activity(activities)

      expect_to_see_total_of_actual_amounts(activities)
    end

    context "report is in a state where upload is not permissable" do
      scenario "the upload facility is not present" do
        report = create(:report, state: :approved, organisation: organisation, description: nil)

        visit report_path(report.id)

        click_link "Actuals"

        expect(page).not_to have_link(t("action.transaction.upload.link"))
      end
    end
  end
end
