RSpec.feature "Users can view an organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:delivery_partner_organisation)
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

        expect(page).to_not have_content(t("default.link.back"))
      end
    end

    context "viewing another organisation" do
      let!(:other_organisation) { create(:delivery_partner_organisation) }

      scenario "can see the other organisation's page" do
        visit organisation_path(user.organisation)
        click_link t("page_title.organisation.index")
        within("##{other_organisation.id}") do
          click_link t("default.link.show")
        end
        expect(page).to have_content(other_organisation.name)
      end

      scenario "does not see activities which belong to a different organisation" do
        other_programme = create(:programme_activity, extending_organisation: create(:delivery_partner_organisation))
        other_project = create(:project_activity, organisation: create(:delivery_partner_organisation))

        visit organisation_path(user.organisation)
        click_link t("page_title.organisation.index")
        within("##{other_organisation.id}") do
          click_link t("default.link.show")
        end

        expect(page).to_not have_content(other_programme.title)
        expect(page).to_not have_content(other_project.title)
      end

      scenario "can go back to the previous page" do
        visit organisation_path(user.organisation)
        click_link t("page_title.organisation.index")

        within("##{other_organisation.id}") do
          click_link t("default.link.show")
        end
        expect(page).to have_content(other_organisation.name)
        click_on t("default.link.back")

        expect(page).to have_current_path(organisations_path)
      end

      scenario "cannot add a child activity" do
        gcrf = create(:fund_activity, :gcrf)
        create(:programme_activity, parent: gcrf, extending_organisation: other_organisation)
        _report = create(:report, :active, fund: gcrf, organisation: other_organisation)

        visit organisation_path(other_organisation)

        expect(page).to_not have_link(t("action.activity.add_child"), exact: true)
      end
    end
  end

  context "when the user does not belong to BEIS" do
    let(:organisation) { create(:delivery_partner_organisation) }

    before do
      authenticate!(user: create(:administrator, organisation: organisation))
    end

    scenario "can see their organisation page" do
      visit organisation_path(organisation)

      expect(page).to have_content(organisation.name)
    end

    scenario "can see a list of their programmes, grouped by fund" do
      newton = create(:fund_activity, :newton)
      newton_funded_programmes = create_list(:programme_activity, 3, parent: newton, extending_organisation: organisation)

      gcrf = create(:fund_activity, :gcrf)
      gcrf_funded_programmes = create_list(:programme_activity, 2, parent: gcrf, extending_organisation: organisation)

      visit organisation_path(organisation)

      within_table(id: newton.id) do
        newton_funded_programmes.each do |programme|
          within(id: programme.id) do
            expect(page).to have_content(programme.title)
            expect(page).to have_content(programme.roda_identifier_compound)
            expect(page).to have_link(t("default.link.view"))
          end
        end
      end

      within_table(id: gcrf.id) do
        gcrf_funded_programmes.each do |programme|
          within(id: programme.id) do
            expect(page).to have_content(programme.title)
            expect(page).to have_content(programme.roda_identifier_compound)
            expect(page).to have_link(t("default.link.view"))
          end
        end
      end
    end

    scenario "clicking the 'view' link goes to the activity details page" do
      gcrf = create(:fund_activity, :gcrf)
      programme = create(:programme_activity, parent: gcrf, extending_organisation: organisation)

      visit organisation_path(organisation)

      within(id: programme.id) do
        click_link t("default.link.view")
      end

      expected_path = organisation_activity_details_path(organisation, programme)
      expect(page.current_path).to eq(expected_path)

      within("h1") do
        expect(page).to have_content(programme.title)
      end
    end

    scenario "can create a new child activity for a given programme" do
      gcrf = create(:fund_activity, :gcrf)
      programme = create(:programme_activity, parent: gcrf, extending_organisation: organisation)
      _report = create(:report, :active, fund: gcrf, organisation: organisation)

      visit organisation_path(organisation)

      within(id: programme.id) do
        click_link t("action.activity.add_child")
      end

      fill_in "activity[delivery_partner_identifier]", with: "foo"
      click_button t("form.button.activity.submit")

      expect(page).to have_content t("form.label.activity.roda_identifier_fragment", level: "programme")
    end

    scenario "cannot add a new child activity when a report does not exist" do
      gcrf = create(:fund_activity, :gcrf)
      programme = create(:programme_activity, parent: gcrf, extending_organisation: organisation)

      visit organisation_path(organisation)

      within(id: programme.id) do
        expect(page).to_not have_link(t("action.activity.add_child"))
      end
    end

    scenario "does not see a back link on their organisation home page" do
      visit organisation_path(organisation)

      expect(page).to_not have_content(t("default.link.back"))
    end
  end
end
