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
      visit new_fund_activity_path(fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the hierarchy is a Fund" do
    scenario "successfully creating an activity" do
      visit new_fund_activity_path(fund)

      expect(page).to have_content(I18n.t("page_title.activity.new"))
      fill_in "activity[identifier]", with: "A-Unique-Identifier"
      click_button I18n.t("form.organisation.submit")
      expect(page).to have_content I18n.t("form.activity.create.success")
    end

    scenario "can go back to the previous page" do
      visit new_fund_activity_path(fund)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(activities_path)
    end
  end
end
