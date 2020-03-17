RSpec.feature "Users can view an organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before do
      authenticate!(user: user)
    end

    context "viewing their own organisation" do
      scenario "can see their own organisation page" do
        visit organisation_path(user.organisation)

        expect(page).to have_content(user.organisation.name)
      end

      scenario "does not see a back link on their organisation page" do
        visit organisation_path(user.organisation)

        expect(page).to_not have_content(I18n.t("generic.link.back"))
      end

      scenario "can see a list of fund activities" do
        fund = create(:fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)

        expect(page).to have_content(fund.title)
      end

      scenario "fund activities are ordered by created_at (oldest first)" do
        fund_1 = create(:fund_activity, organisation: user.organisation, created_at: Date.yesterday)
        fund_2 = create(:fund_activity, organisation: user.organisation, created_at: Date.today)

        visit organisation_path(user.organisation)

        expect(page.find("ul.funds li:first-child")).to have_content(fund_1.title)
        expect(page.find("ul.funds li:last-child")).to have_content(fund_2.title)
      end
    end

    context "viewing another organisation" do
      let!(:other_organisation) { create(:organisation) }

      scenario "can see the other organisation's page" do
        visit organisation_path(user.organisation)
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        click_link other_organisation.name

        expect(page).to have_content(other_organisation.name)
      end

      scenario "can go back to the previous page" do
        visit organisation_path(user.organisation)
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        click_link other_organisation.name

        click_on I18n.t("generic.link.back")

        expect(page).to have_current_path(organisations_path)
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:organisation) { create(:organisation) }

    before do
      authenticate!(user: create(:administrator, organisation: organisation))
    end

    scenario "can see their organisation page" do
      visit organisation_path(organisation)

      expect(page).to have_content(organisation.name)
    end

    scenario "does not see a back link on their organisation home page" do
      visit organisation_path(organisation)

      expect(page).to_not have_content(I18n.t("generic.link.back"))
    end

    scenario "can see a list of programme activities" do
      programme = create(:programme_activity, organisation: organisation)

      visit organisation_path(organisation)

      expect(page).to have_content(programme.title)
    end

    scenario "programme activities are ordered by created_at (oldest first)" do
      programme_1 = create(:programme_activity, organisation: organisation, created_at: Date.yesterday)
      programme_2 = create(:programme_activity, organisation: organisation, created_at: Date.today)

      visit organisation_path(organisation)

      expect(page.find("ul.programmes li:first-child")).to have_content(programme_1.title)
      expect(page.find("ul.programmes li:last-child")).to have_content(programme_2.title)
    end
  end
end
