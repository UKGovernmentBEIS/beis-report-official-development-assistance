RSpec.feature "Users can view a fund" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:organisation_2) { create(:organisation) }
  let!(:viewable_fund) { create(:fund, organisation: organisation) }
  let!(:forbidden_fund) { create(:fund, organisation: organisation_2) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit fund_path(viewable_fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the fund belongs to the user's organisation" do
    scenario "the user can view the fund" do
      visit fund_path(viewable_fund)

      expect(page).to have_content viewable_fund.name
    end
  end

  context "when the fund belongs to another organisation" do
    scenario "the user cannot view the fund" do
      expect { visit fund_path(forbidden_fund) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  scenario "can go back to the previous page" do
    visit fund_path(viewable_fund)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(organisation_path(organisation.id))
  end
end
