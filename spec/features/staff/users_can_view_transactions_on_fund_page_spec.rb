RSpec.feature "Users can view funds on an organisation page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }
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
end
