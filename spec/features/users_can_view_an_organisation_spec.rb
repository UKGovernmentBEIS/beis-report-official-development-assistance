RSpec.feature "Users can view an organisation" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before do
      authenticate!(user: user)
    end
    after { logout }

    context "viewing their own organisation" do
      scenario "can see their own organisation page" do
        visit organisation_path(user.organisation)

        expect(page).to have_content(user.organisation.name)
      end

      scenario "does not see a back link on their organisation page" do
        visit organisation_path(user.organisation)

        expect(page).to_not have_content(t("default.link.back"))
      end
    end

    context "viewing another organisation" do
      let!(:other_organisation) { create(:partner_organisation) }

      scenario "can see the other organisation's page" do
        visit organisation_path(user.organisation)

        within ".govuk-header__navigation" do
          click_link t("page_title.organisation.index")
        end

        within("##{other_organisation.id}") do
          click_link t("default.link.show")
        end
        expect(page).to have_content(other_organisation.name)
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:organisation) { create(:partner_organisation) }

    before do
      authenticate!(user: create(:administrator, organisation: organisation))
    end

    after { logout }

    scenario "can see their organisation page" do
      visit organisation_path(organisation)

      expect(page).to have_content(organisation.name)
    end

    scenario "does not see a back link on their organisation home page" do
      visit organisation_path(organisation)

      expect(page).to_not have_content(t("default.link.back"))
    end
  end
end
