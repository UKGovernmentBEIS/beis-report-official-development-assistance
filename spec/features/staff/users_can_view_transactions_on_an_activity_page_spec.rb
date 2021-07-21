RSpec.feature "Users can view transactions on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      let(:other_activity) { create(:programme_activity, organisation: user.organisation) }

      scenario "only transactions belonging to this programme activity are shown on the Activity#show page" do
        transaction = create(:transaction, parent_activity: activity, value: "100")
        other_transaction = create(:transaction, parent_activity: other_activity, value: "200")

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_content(transaction.value)
        expect(page).to_not have_content(other_transaction.value)
      end

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, parent_activity: activity)
        transaction_presenter = TransactionPresenter.new(transaction)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_content(transaction_presenter.financial_quarter_and_year)
        expect(page).to have_content(transaction_presenter.value)
        expect(page).to have_content(transaction_presenter.receiving_organisation_name)
      end

      scenario "the transactions are shown in date order, newest first" do
        transaction_1 = create(:transaction, parent_activity: activity, date: Date.today)
        transaction_2 = create(:transaction, parent_activity: activity, date: Date.yesterday)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page.find("table.transactions tbody tr:first-child")[:id]).to eq(transaction_1.id)
        expect(page.find("table.transactions tbody tr:last-child")[:id]).to eq(transaction_2.id)
      end
    end

    context "when the activity is a project" do
      let(:delivery_partner_user) { create(:delivery_partner_user) }
      let(:fund_activity) { create(:fund_activity, organisation: user.organisation) }
      let(:programme_activity) { create(:programme_activity, parent: fund_activity, organisation: user.organisation) }
      let(:project_activity) { create(:project_activity, parent: programme_activity, organisation: delivery_partner_user.organisation) }

      scenario "transaction information is shown on the page" do
        transaction = create(:transaction, parent_activity: project_activity)
        transaction_presenter = TransactionPresenter.new(transaction)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        expect(page).to have_content(transaction_presenter.financial_quarter_and_year)
        expect(page).to have_content(transaction_presenter.value)
        expect(page).to have_content(transaction_presenter.receiving_organisation_name)
      end

      scenario "transactions cannot be created or edited by a BEIS user" do
        transaction = create(:transaction, parent_activity: project_activity)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        expect(page).to_not have_content(t("page_content.transactions.button.create"))
        within("tr##{transaction.id}") do
          expect(page).not_to have_content(t("default.link.edit"))
        end
      end
    end
  end
end
