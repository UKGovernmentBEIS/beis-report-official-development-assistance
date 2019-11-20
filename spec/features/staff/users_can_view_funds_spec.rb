RSpec.feature "Users can view funds" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:organisation_2) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit funds_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when there are funds belonging to the user's organisation" do
    scenario "the user will see them on the funds index page" do
      fund = create(:fund, organisation: organisation)

      visit funds_path

      expect(page).to have_content(I18n.t("page_title.fund.index"))
      expect(page).to have_content fund.name
    end
  end

  context "when there are funds belonging to another organisation" do
    scenario "the user will not see them on the funds index page" do
      fund = create(:fund, organisation: organisation_2)

      visit funds_path

      expect(page).to have_content(I18n.t("page_title.fund.index"))
      expect(page).not_to have_content fund.name
    end
  end

  scenario "can go back to the previous page" do
    visit funds_path

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(dashboard_path)
  end
end
