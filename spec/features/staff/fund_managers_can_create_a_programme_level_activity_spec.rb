RSpec.feature "Fund managers can create programme level activities" do
  let(:organisation) { create(:organisation, name: "BEIS") }

  context "when signed in" do
    before do
      authenticate!(user: create(:fund_manager, organisation: organisation))
    end

    scenario "successfully create an activity" do
      fund = create(:activity, level: :fund, organisation: organisation)

      visit organisation_path(organisation)
      click_on fund.title
      click_on(I18n.t("page_content.organisation.button.create_programme"))

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.programme.create.success")
    end

    scenario "the activity has the appropriate funding organisation defaults" do
      identifier = "a-programme-has-a-funding-organisation"
      fund = create(:activity, level: :fund, organisation: organisation)

      visit organisation_path(organisation)
      click_on fund.title
      click_on(I18n.t("page_content.organisation.button.create_programme"))

      fill_in_activity_form(identifier: identifier)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.funding_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-13")
      expect(activity.funding_organisation_type).to eq("10")
    end
  end
end
