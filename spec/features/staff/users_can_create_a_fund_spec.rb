RSpec.feature "Users can create a fund" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit funds_path
      expect(current_path).to eq(root_path)
    end
  end

  scenario "successfully creating a fund" do
    visit new_organisation_fund_path(organisation_id: organisation.id)

    expect(page).to have_content(I18n.t("page_title.fund.new"))
    fill_in "fund[name]", with: "My Space Fund"
    click_button I18n.t("form.fund.submit")
    expect(page).to have_content I18n.t("form.fund.create.success")
  end

  scenario "presence validation works as expected" do
    visit visit new_organisation_fund_path(organisation_id: organisation.id)

    expect(page).to have_content(I18n.t("page_title.fund.new"))

    click_button I18n.t("form.fund.submit")
    expect(page).to_not have_content I18n.t("form.fund.create.success")
    expect(page).to have_content "can't be blank"
  end
end
