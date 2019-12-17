RSpec.feature "Users can create an activity" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let!(:fund) { create(:fund, organisation: organisation, name: "My Space Fund") }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the hierarchy is a Fund" do
    scenario "successfully creating an activity with all optional information" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")

      fill_in_activity_form
    end

    scenario "the activity form has some defaults" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")
      activity = Activity.last

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :country)
      expect(page.find("option[@selected = 'selected']").text).to eq("Developing countries, unspecified")

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq("ODA")

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :tied_status)
      expect(page.find("option[@selected = 'selected']").text).to eq("Untied")
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit organisation_fund_path(organisation, fund)
        click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "can't be blank"
      end
    end

    scenario "can go back to the previous page" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(fund.id, organisation_id: organisation.id))
    end
  end
end
