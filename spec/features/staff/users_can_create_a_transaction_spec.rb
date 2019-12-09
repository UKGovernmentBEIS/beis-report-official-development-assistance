RSpec.feature "Users can create a transaction" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let!(:fund) { create(:fund, organisation: organisation, name: "My Space Fund") }
  let!(:activity) { create(:activity, hierarchy: fund) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  scenario "an incoming fund transaction" do
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

    click_on(organisation.name)
    click_on(fund.name)

    click_on(I18n.t("page_content.transactions.button.create"))

    fill_in "transaction[reference]", with: "123"
    fill_in "transaction[description]", with: "This money will be purchasing a new school roof"
    select "Outgoing Pledge", from: "transaction[transaction_type]"
    fill_in "transaction[date(3i)]", with: "1"
    fill_in "transaction[date(2i)]", with: "1"
    fill_in "transaction[date(1i)]", with: "2020"
    fill_in "transaction[value]", with: "1000.01"
    select "Money is disbursed through central Ministry of Finance or Treasury", from: "transaction[disbursement_channel]"
    select "Pound Sterling", from: "transaction[currency]"
    click_on(I18n.t("generic.button.submit"))

    expect(page).to have_content(I18n.t("form.transaction.create.success"))
    within ".transactions" do
      expect(page).to have_content("123")
      expect(page).to have_content("This money will be purchasing a new school roof")
      expect(page).to have_content(I18n.t("transaction.transaction_type.12"))
      expect(page).to have_content("2020-01-01")
      expect(page).to have_content("1000.01")
      expect(page).to have_content(I18n.t("transaction.disbursement_channel.1"))
      expect(page).to have_content(I18n.t("generic.default_currency.gbp"))
    end
  end

  scenario "validations" do
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

    click_on(organisation.name)
    click_on(fund.name)

    click_on(I18n.t("page_content.transactions.button.create"))
    click_on(I18n.t("generic.button.submit"))

    expect(page).to_not have_content(I18n.t("form.transaction.create.success"))
    expect(page).to have_content("Reference can't be blank")
    expect(page).to have_content("Description can't be blank")
    expect(page).to have_content("Transaction type can't be blank")
    expect(page).to have_content("Date can't be blank")
    expect(page).to have_content("Value can't be blank")
    expect(page).to have_content("Disbursement channel can't be blank")
  end
end
