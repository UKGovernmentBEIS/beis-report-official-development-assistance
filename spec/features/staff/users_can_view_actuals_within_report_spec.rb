RSpec.feature "Users can view actuals in tab within a report" do
  context "as a partner organisation user" do
    let(:organisation) { create(:partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: user)
    end

    def expect_to_see_a_table_of_actuals_grouped_by_activity(activities)
      fail "We expect some activities to be present" if activities.none?

      activities.each do |activity|
        within "#activity_actuals_#{activity.id}" do
          expect(page).to have_content(activity.title)
          expect(page).to have_content(activity.roda_identifier)

          fail "We expect some actuals to be present" if activity.actuals.none?

          activity.actuals.each do |actual|
            within ".actuals" do
              expect(page).to have_content(actual.value)
              expect(page).to have_content(actual.financial_quarter_and_year)
            end
          end
        end
      end
    end

    def expect_to_see_a_table_of_refunds_grouped_by_activity(activities)
      fail "We expect some activities to be present" if activities.none?

      activities.each do |activity|
        within "#activity_refunds_#{activity.id}" do
          expect(page).to have_content(activity.title)
          expect(page).to have_content(activity.roda_identifier)

          fail "We expect some refunds to be present" if activity.refunds.none?

          activity.refunds.each do |refund|
            within ".refunds" do
              expect(page).to have_content(TransactionPresenter.new(refund).value)
              expect(page).to have_content(refund.financial_quarter_and_year)
            end
          end
        end
      end
    end

    def expect_to_see_total_of_actual_amounts(activities)
      actuals_total = activities.map(&:actuals).flatten.sum(&:value)

      within "#actuals .totals" do
        expect(page).to have_content(
          ActionController::Base.helpers.number_to_currency(actuals_total, unit: "£")
        )
      end
    end

    def expect_to_see_total_of_refund_amounts(activities)
      refund_total = activities.map(&:refunds).flatten.sum(&:value)

      within "#refunds .totals" do
        expect(page).to have_content(
          ActionController::Base.helpers.number_to_currency(refund_total, unit: "£")
        )
      end
    end

    scenario "the report contains an _actuals_ tab" do
      report = create(:report, :active, organisation: organisation, description: nil)

      programme = create(:programme_activity)
      project = create(:project_activity, organisation: organisation, parent: programme)

      activities = [
        create(:third_party_project_activity,
          organisation: organisation,
          parent: project).tap do |activity|
          create(:actual, report: report, parent_activity: activity)
          create(:refund, report: report, parent_activity: activity)
        end,
        create(:third_party_project_activity,
          organisation: organisation,
          parent: project).tap do |activity|
          create_list(:actual, 3, report: report, parent_activity: activity)
          create_list(:refund, 4, report: report, parent_activity: activity)
        end
      ]

      visit report_path(report.id)

      click_link t("tabs.report.actuals.heading")

      expect(page).to have_content("Actuals")
      expect(page).to have_link(t("action.actual.upload.link"))

      expect_to_see_a_table_of_actuals_grouped_by_activity(activities)
      expect_to_see_a_table_of_refunds_grouped_by_activity(activities)

      expect_to_see_total_of_actual_amounts(activities)
    end

    context "report is in a state where upload is not permissable" do
      scenario "the upload facility is not present" do
        report = create(:report, :approved, organisation: organisation, description: nil)

        visit report_path(report.id)

        click_link "Actuals"

        expect(page).not_to have_link(t("action.actual.upload.link"))
      end
    end
  end
end
