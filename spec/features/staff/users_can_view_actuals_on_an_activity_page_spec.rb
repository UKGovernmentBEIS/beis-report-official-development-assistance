RSpec.feature "Users can view actuals on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      let(:other_activity) { create(:programme_activity, organisation: user.organisation) }

      scenario "only actuals belonging to this programme activity are shown on the Activity#show page" do
        actual = create(:actual, parent_activity: activity, value: "100")
        other_actual = create(:actual, parent_activity: other_activity, value: "200")

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_content(actual.value)
        expect(page).to_not have_content(other_actual.value)
      end

      scenario "actual information is shown on the page" do
        actual = create(:actual, parent_activity: activity)
        actual_presenter = TransactionPresenter.new(actual)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_content(actual_presenter.financial_quarter_and_year)
        expect(page).to have_content(actual_presenter.value)
        expect(page).to have_content(actual_presenter.receiving_organisation_name)
      end

      scenario "the actuals are shown in date order, newest first" do
        actual_1 = create(:actual, parent_activity: activity, date: Date.today)
        actual_2 = create(:actual, parent_activity: activity, date: Date.yesterday)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page.find("table.actuals tbody tr:first-child")[:id]).to eq(actual_1.id)
        expect(page.find("table.actuals tbody tr:last-child")[:id]).to eq(actual_2.id)
      end
    end

    context "when the activity is a project" do
      let(:partner_org_user) { create(:delivery_partner_user) }
      let(:fund_activity) { create(:fund_activity, organisation: user.organisation) }
      let(:programme_activity) { create(:programme_activity, parent: fund_activity, organisation: user.organisation) }
      let(:project_activity) { create(:project_activity, parent: programme_activity, organisation: partner_org_user.organisation) }

      scenario "actual information is shown on the page" do
        actual = create(:actual, parent_activity: project_activity)
        actual_presenter = TransactionPresenter.new(actual)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        expect(page).to have_content(actual_presenter.financial_quarter_and_year)
        expect(page).to have_content(actual_presenter.value)
        expect(page).to have_content(actual_presenter.receiving_organisation_name)
      end

      scenario "actuals cannot be created or edited by a BEIS user" do
        actual = create(:actual, parent_activity: project_activity)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        expect(page).to_not have_content(t("page_content.actuals.button.create"))
        within("tr##{actual.id}") do
          expect(page).not_to have_content(t("default.link.edit"))
        end
      end
    end
  end
end
