RSpec.describe "Users can edit an external income" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }

    let!(:project) { create(:project_activity, :with_report, organisation: user.organisation, parent: programme) }
    let!(:external_income_provider) { create(:external_income_provider) }
    let!(:external_income) { create(:external_income, activity: project, financial_quarter: 1, oda_funding: true) }

    before { authenticate!(user: user) }

    before do
      visit organisation_activity_path(project.organisation, project)
      click_on "Other funding"
      find("a[href='#{edit_activity_external_income_path(project, external_income)}']").click
    end

    scenario "they can edit a matched effort" do
      external_income.organisation = external_income_provider
      external_income.financial_quarter = 4
      external_income.oda_funding = false

      fill_in_external_income_form(external_income)

      expect(page).to have_content(t("action.external_income.update.success"))

      expect(external_income.reload.organisation).to eq(external_income_provider)
      expect(external_income.financial_quarter).to eq(4)
      expect(external_income.oda_funding).to eq(false)
    end

    scenario "they see errors when a required field is missing" do
      select("", from: "external_income[organisation_id]")
      click_on t("default.button.submit")

      expect(page).to_not have_content(t("action.external_income.update.success"))

      expect(page).to have_content("Organisation can't be blank")
    end
  end
end
