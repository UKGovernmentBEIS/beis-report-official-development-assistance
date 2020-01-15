RSpec.feature "Users can view funds on an organisation page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:user) { create(:administrator, organisation: organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let(:other_fund) { create(:fund, organisation: organisation) }

  scenario "only transactions belonging to this fund are shown on the Fund#show page" do
    transaction = create(:transaction, fund: fund)
    other_transaction = create(:transaction, fund: other_fund)

    visit organisations_path
    click_link organisation.name
    click_link fund.name

    expect(page).to have_content(transaction.reference)
    expect(page).to_not have_content(other_transaction.reference)
  end

  scenario "transaction information is shown on the page" do
    transaction = create(:transaction, fund: fund)
    transaction_presenter = TransactionPresenter.new(transaction)

    visit organisations_path
    click_link organisation.name
    click_link fund.name

    expect(page).to have_content(transaction_presenter.reference)
    expect(page).to have_content(transaction_presenter.description)
    expect(page).to have_content(transaction_presenter.transaction_type)
    expect(page).to have_content(transaction_presenter.date)
    expect(page).to have_content(transaction_presenter.currency)
    expect(page).to have_content(transaction_presenter.value)
    expect(page).to have_content(transaction_presenter.disbursement_channel)
    expect(page).to have_content(transaction_presenter.receiver.name)
    expect(page).to have_content(transaction_presenter.provider.name)
  end
end
