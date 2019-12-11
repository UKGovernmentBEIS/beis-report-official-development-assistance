RSpec.feature "Users can edit a transaction" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let!(:fund) { create(:fund, organisation: organisation) }
  let!(:transaction) { create(:transaction, fund: fund) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  scenario "going back to the previous page" do
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
    click_on(organisation.name)
    click_on(fund.name)

    expect(page).to have_content(transaction.reference)

    within("##{transaction.id}") do
      click_on(I18n.t("generic.link.edit"))
    end
    click_on(I18n.t("generic.link.back"))

    expect(page).to have_content(fund.name)
  end

  scenario "editing a transaction" do
    visit dashboard_path
    click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
    click_on(organisation.name)
    click_on(fund.name)

    expect(page).to have_content(transaction.reference)

    within("##{transaction.id}") do
      click_on(I18n.t("generic.link.edit"))
    end
    fill_in "transaction[reference]", with: "new-transaction-reference"
    fill_in "transaction[description]", with: "This money will be buying some books for students"
    select "Expenditure", from: "transaction[transaction_type]"
    fill_in "transaction[date(3i)]", with: "1"
    fill_in "transaction[date(2i)]", with: "1"
    fill_in "transaction[date(1i)]", with: "2021"
    fill_in "transaction[value]", with: "2000.51"
    select "Aid in kind: Donors manage funds themselves", from: "transaction[disbursement_channel]"
    select "US Dollar", from: "transaction[currency]"
    click_on(I18n.t("generic.button.submit"))

    expect(page).to have_content(I18n.t("form.transaction.update.success"))
    expect(page).to have_content("new-transaction-reference")
    expect(page).to have_content("This money will be buying some books for students")
    expect(page).to have_content("2021-01-01")
  end
end
