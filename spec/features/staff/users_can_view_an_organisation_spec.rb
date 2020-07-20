RSpec.feature "Users can view an organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
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

        expect(page).to_not have_content(I18n.t("default.link.back"))
      end
    end

    context "viewing another organisation" do
      let!(:other_organisation) { create(:organisation) }

      scenario "can see the other organisation's page" do
        visit organisation_path(user.organisation)
        click_link I18n.t("page_title.organisation.index")
        within("##{other_organisation.id}") do
          click_link I18n.t("default.link.show")
        end
        expect(page).to have_content(other_organisation.name)
      end

      scenario "sees activities which belong to this organisation" do
        programme = create(:programme_activity, extending_organisation: other_organisation)
        project = create(:project_activity, organisation: other_organisation)

        visit organisation_path(user.organisation)
        click_link I18n.t("page_title.organisation.index")
        within("##{other_organisation.id}") do
          click_link I18n.t("default.link.show")
        end

        expect(page).to have_content(programme.title)
        expect(page).to have_content(project.title)
      end

      scenario "does not see activities which belong to a different organisation" do
        other_programme = create(:programme_activity, extending_organisation: create(:organisation))
        other_project = create(:project_activity, organisation: create(:organisation))

        visit organisation_path(user.organisation)
        click_link I18n.t("page_title.organisation.index")
        within("##{other_organisation.id}") do
          click_link I18n.t("default.link.show")
        end

        expect(page).to_not have_content(other_programme.title)
        expect(page).to_not have_content(other_project.title)
      end

      scenario "can go back to the previous page" do
        visit organisation_path(user.organisation)
        click_link I18n.t("page_title.organisation.index")

        within("##{other_organisation.id}") do
          click_link I18n.t("default.link.show")
        end
        expect(page).to have_content(other_organisation.name)
        click_on I18n.t("default.link.back")

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

      expect(page).to_not have_content(I18n.t("default.link.back"))
    end

    scenario "can see a list of programme activities" do
      programme = create(:programme_activity,
        organisation: organisation,
        extending_organisation: organisation)

      visit organisation_path(organisation)

      expect(page).to have_content(programme.title)
    end

    scenario "programme activities are ordered by created_at (oldest first)" do
      programme_1 = create(:programme_activity,
        organisation: organisation,
        created_at: Date.yesterday,
        extending_organisation: organisation)
      programme_2 = create(:programme_activity,
        organisation: organisation,
        created_at: Date.today,
        extending_organisation: organisation)

      visit organisation_path(organisation)

      expect(page.find("table.programmes  tbody tr:first-child")[:id]).to have_content(programme_1.id)
      expect(page.find("table.programmes  tbody tr:last-child")[:id]).to have_content(programme_2.id)
    end
  end
end
