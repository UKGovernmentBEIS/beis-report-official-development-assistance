RSpec.feature "Users can view transactions on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    let(:activity) { create(:fund_activity, organisation: user.organisation) }
    let(:other_activity) { create(:fund_activity, organisation: user.organisation) }

    scenario "only transactions belonging to this fund activity are shown on the Activity#show page" do
      transaction = create(:transaction, activity: activity)
      other_transaction = create(:transaction, activity: other_activity)

      visit organisation_path(user.organisation)

      click_link activity.title

      expect(page).to have_content(transaction.reference)
      expect(page).to_not have_content(other_transaction.reference)
    end

    scenario "transaction information is shown on the page" do
      transaction = create(:transaction, activity: activity)
      transaction_presenter = TransactionPresenter.new(transaction)

      visit organisation_path(user.organisation)

      click_link activity.title

      expect(page).to have_content(transaction_presenter.reference)
      expect(page).to have_content(transaction_presenter.transaction_type)
      expect(page).to have_content(transaction_presenter.date)
      expect(page).to have_content(transaction_presenter.currency)
      expect(page).to have_content(transaction_presenter.value)
      expect(page).to have_content(transaction_presenter.disbursement_channel)
      expect(page).to have_content(transaction_presenter.providing_organisation_name)
      expect(page).to have_content(transaction_presenter.receiving_organisation_name)
    end

    scenario "the transactions are shown in date order, newest first" do
      transaction_1 = create(:transaction, activity: activity, date: Date.today)
      transaction_2 = create(:transaction, activity: activity, date: Date.yesterday)

      visit organisation_path(user.organisation)

      click_link activity.title

      expect(page.find("table.transactions tbody tr:first-child")[:id]).to eq(transaction_1.id)
      expect(page.find("table.transactions tbody tr:last-child")[:id]).to eq(transaction_2.id)
    end
  end
end
