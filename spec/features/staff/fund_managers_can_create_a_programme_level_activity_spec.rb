RSpec.feature "Fund managers can create programme level activities" do
  let(:organisation) { create(:organisation, name: "BEIS") }

  context "when signed in" do
    before do
      authenticate!(user: create(:fund_manager, organisation: organisation))
    end

    scenario "successfully create a activity" do
      fund = create(:activity, level: :fund, organisation: organisation)

      visit organisation_path(organisation)
      click_on fund.title
      click_on(I18n.t("page_content.organisation.button.create_programme"))

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.programme.create.success")
    end
  end
end
