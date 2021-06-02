RSpec.describe "Users can create a external income" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }

    let!(:project) { create(:project_activity, :with_report, organisation: user.organisation, parent: programme) }
    let!(:external_income_provider) { create(:external_income_provider) }

    before { authenticate!(user: user) }

    before do
      visit organisation_activity_path(project.organisation, project)

      click_on "Other funding"
      click_on t("page_content.external_income.button.create")
    end

    scenario "they can add an external income" do
      template = build(:external_income,
        organisation: external_income_provider,
        amount: "2345",
        financial_quarter: 1,
        financial_year: 2021,
        oda_funding: true)

      fill_in_external_income_form(template)

      expect(page).to have_content(t("action.external_income.create.success"))

      external_income = ExternalIncome.order("created_at ASC").last

      expect(external_income.organisation).to eq(external_income_provider)
      expect(external_income.financial_quarter).to eq(1)
      expect(external_income.financial_year).to eq(2021)
      expect(external_income.amount).to eq(2345.00)
      expect(external_income.oda_funding).to eq(true)

      within("table.implementing_organisations") do
        expect(page).to have_content(external_income_provider.name)
        expect(page).to have_content("FQ1 2021-2022")
        expect(page).to have_content("£2,345.00")
        expect(page).to have_content("Yes")
      end
    end

    scenario "creation is tracked with PublicActivity" do
      template = build(:external_income, organisation: external_income_provider)

      PublicActivity.with_tracking do
        fill_in_external_income_form(template)

        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "external_income.create"
        expect(auditable_event.owner_id).to eq user.id
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
