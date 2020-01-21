RSpec.feature "Users can create a transaction" do
  let(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      fund = create(:fund, organisation: organisation)
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisation: organisation)) }

    scenario "successfully creates a transaction on a fund" do
      fund = create(:fund, organisation: organisation)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

      click_on(organisation.name)
      click_on(fund.name)

      click_on(I18n.t("page_content.transactions.button.create"))

      fill_in_transaction_form

      expect(page).to have_content(I18n.t("form.transaction.create.success"))
    end

    scenario "validations" do
      fund = create(:fund, organisation: organisation)

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
      expect(page).to have_content("Value must be between 1 and 99,999,999,999.00")
      expect(page).to have_content("Disbursement channel can't be blank")
    end

    context "Value number validation" do
      scenario "Value must be between 1 and 99,999,999,999" do
        fund = create(:fund, organisation: organisation)

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
        fill_in "transaction[value]", with: "100000000000"
        select "Money is disbursed through central Ministry of Finance or Treasury", from: "transaction[disbursement_channel]"
        select "Pound Sterling", from: "transaction[currency]"
        click_on(I18n.t("generic.button.submit"))

        expect(page).to have_content("Value must be between 1 and 99,999,999,999.00")
      end

      scenario "When the value includes a pound sign" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "£123", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes alphabetical characters" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "abc123def", expectations: false)

        expect(page).to have_content "123"
      end

      scenario "When the value includes decimal places" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "100.12", expectations: false)

        expect(page).to have_content "100.12"
      end

      scenario "When the value includes commas" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(value: "123,000,000", expectations: false)

        expect(page).to have_content "123000000"
      end
    end

    context "Date validation" do
      scenario "When the date is more than 25 years in the future" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(date_day: 0o1, date_month: 0o1, date_year: 2100, expectations: false)

        expect(page).to have_content "Date must be between 10 years ago and 25 years in the future"
      end

      scenario "When the date is more than 10 years in the past" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(date_day: 0o1, date_month: 0o1, date_year: 1900, expectations: false)

        expect(page).to have_content "Date must be between 10 years ago and 25 years in the future"
      end

      scenario "When the date is nil" do
        fund = create(:fund, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.name)

        click_on(I18n.t("page_content.transactions.button.create"))

        fill_in_transaction_form(date_day: "", date_month: "", date_year: "", expectations: false)

        expect(page).to_not have_content "Date must be between 10 years ago and 25 years in the future"
      end
    end

    # TODO: When we come to create transactions for different types of activity
    # for projects and programmes etc, we will want to test that users who are
    # deliver partners can create transactions for project activities too.
    context "when the user is a delivery_partner" do
      before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

      scenario "cannot create an transaction that belongs to a fund activity" do
        fund = create(:fund, organisation: organisation)

        visit new_fund_transaction_path(fund)

        expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      end
    end
  end
end
