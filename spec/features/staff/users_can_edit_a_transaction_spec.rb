RSpec.feature "Users can edit a transaction" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let!(:fund) { create(:fund, organisation: organisation) }
  let!(:transaction) { create(:transaction, fund: fund) }
  let(:user) { create(:administrator, organisation: organisation) }

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

    fill_in_transaction_form(
      reference: "new-transaction-reference",
      description: "This money will be buying some books for students",
      transaction_type: "Expenditure",
      date_day: "1",
      date_month: "1",
      date_year: "2021",
      value: "2000.51",
      disbursement_channel: "Aid in kind: Donors manage funds themselves",
      currency: "US Dollar",
      provider_organisation: organisation,
      receiver_organisation: organisation
    )

    expect(page).to have_content(I18n.t("form.transaction.update.success"))
  end
end
