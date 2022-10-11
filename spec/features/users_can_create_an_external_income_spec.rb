RSpec.describe "Users can create a external income" do
  context "when signed in as a partner organisation user" do
    let(:financial_quarter) { FinancialQuarter.new(Time.current.year, 1) }
    let(:user) { create(:partner_organisation_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }

    let!(:project) { create(:project_activity, :with_report, organisation: user.organisation, parent: programme) }
    let!(:external_income_provider) { create(:external_income_provider) }

    before { authenticate!(user: user) }

    after { logout }

    before do
      visit organisation_activity_path(project.organisation, project)

      click_on "Other funding"
      click_on t("page_content.external_income.button.create")
    end

    scenario "they can add an external income" do
      template = build(:external_income,
        organisation: external_income_provider,
        amount: "2345",
        financial_quarter: financial_quarter.quarter,
        financial_year: financial_quarter.financial_year.start_year,
        oda_funding: true)

      fill_in_external_income_form(template)

      expect(page).to have_content(t("action.external_income.create.success"))

      external_income = ExternalIncome.order("created_at ASC").last

      expect(external_income.organisation).to eq(external_income_provider)
      expect(external_income.financial_quarter).to eq(financial_quarter.quarter)
      expect(external_income.financial_year).to eq(financial_quarter.financial_year.start_year)
      expect(external_income.amount).to eq(2345.00)
      expect(external_income.oda_funding).to eq(true)

      within("table.implementing_organisations") do
        expect(page).to have_content(external_income_provider.name)
        expect(page).to have_content(financial_quarter.to_s)
        expect(page).to have_content("£2,345.00")
        expect(page).to have_content("Yes")
      end
    end

    context "when the current fin. year has advanced from the period being reported" do
      scenario "can choose the previous financial year" do
        options = page.all("#external-income-financial-year-field option").map(&:text)
        expect(options).to include(FinancialYear.new(Date.today.year).pred.to_s)
      end
    end

    scenario "they are shown errors when required fields are left blank" do
      click_on t("default.button.submit")

      expect(page).to have_content("Organisation can't be blank")
      expect(page).to have_content("Financial quarter can't be blank")
      expect(page).to have_content("Amount can't be blank")
    end
  end
end
