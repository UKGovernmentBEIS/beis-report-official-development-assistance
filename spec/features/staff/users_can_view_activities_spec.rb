RSpec.feature "Users can view activities (on a fund page)" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let(:user) { create(:administrator, organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(id: fund.id, organisation_id: organisation.id)
      expect(current_path).to eq(root_path)
    end
  end

  context "when there is an activity belonging to a fund in the user's organisation" do
    scenario "the user will see it on the fund show page" do
      activity = create(:activity, hierarchy: fund)

      visit organisation_fund_path(id: fund.id, organisation_id: organisation.id)

      expect(page).to have_content(activity.identifier)
    end
  end

  scenario "can go back to the previous page" do
    visit organisation_fund_path(id: fund.id, organisation_id: organisation.id)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(organisation_path(organisation.id))
  end
end
