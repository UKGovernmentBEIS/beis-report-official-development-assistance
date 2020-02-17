RSpec.feature "Users can view transactions on an activity page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:user) { create(:administrator, organisation: organisation) }
  let(:activity) { create(:activity, organisation: organisation) }
  let(:other_activity) { create(:activity, organisation: organisation) }

  scenario "only transactions belonging to this activity are shown on the Activity#show page" do
    transaction = create(:transaction, activity: activity)
    other_transaction = create(:transaction, activity: other_activity)

    visit organisation_path(organisation)

    click_link activity.title

    expect(page).to have_content(transaction.reference)
    expect(page).to_not have_content(other_transaction.reference)
  end

  scenario "transaction information is shown on the page" do
    transaction = create(:transaction, activity: activity)
    transaction_presenter = TransactionPresenter.new(transaction)

    visit organisation_path(organisation)

    click_link activity.title

    expect(page).to have_content(transaction_presenter.reference)
    expect(page).to have_content(transaction_presenter.description)
    expect(page).to have_content(transaction_presenter.transaction_type)
    expect(page).to have_content(transaction_presenter.date)
    expect(page).to have_content(transaction_presenter.currency)
    expect(page).to have_content(transaction_presenter.value)
    expect(page).to have_content(transaction_presenter.disbursement_channel)
    expect(page).to have_content(transaction_presenter.providing_organisation_name)
    expect(page).to have_content(transaction_presenter.receiving_organisation_name)
  end
end
