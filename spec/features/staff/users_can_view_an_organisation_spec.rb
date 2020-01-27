RSpec.feature "Users can view an organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund manager" do
    let(:organisation) { create(:organisation) }

    before do
      authenticate!(user: create(:fund_manager, organisation: organisation))
    end

    context "viewing their own organisation" do
      scenario "can see their own organisation page" do
        visit organisation_path(organisation)

        expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
      end

      scenario "does not see a back link on their organisation page" do
        visit organisation_path(organisation)

        expect(page).to_not have_content(I18n.t("generic.link.back"))
      end
    end

    context "viewing another organisation" do
      let!(:other_organisation) { create(:organisation) }

      scenario "can see the other organisation's page" do
        visit organisation_path(organisation)
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        click_link other_organisation.name

        expect(page).to have_content(I18n.t("page_title.organisation.show", name: other_organisation.name))
      end

      scenario "can go back to the previous page" do
        visit organisation_path(organisation)
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        click_link other_organisation.name

        click_on I18n.t("generic.link.back")

        expect(page).to have_current_path(organisations_path)
      end
    end
  end

  context "when the user is a delivery_partner" do
    let(:organisation) { create(:organisation) }

    before do
      authenticate!(user: create(:delivery_partner, organisation: organisation))
    end

    scenario "can see their organisation page" do
      visit organisation_path(organisation)

      expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
    end

    scenario "does not see a back link on their organisation home page" do
      visit organisation_path(organisation)

      expect(page).to_not have_content(I18n.t("generic.link.back"))
    end
  end
end
