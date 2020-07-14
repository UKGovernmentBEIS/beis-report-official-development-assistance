feature "Organisation show page" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  let(:fund) { create(:fund_activity, organisation: beis_user.organisation) }
  let!(:incomplete_fund) { create(:fund_activity, :at_purpose_step, organisation: beis_user.organisation) }
  let(:programme) do
    create(:programme_activity,
      parent: fund,
      organisation: beis_user.organisation,
      extending_organisation: delivery_partner_user.organisation)
  end
  let!(:incomplete_programme) { create(:programme_activity, :at_purpose_step, extending_organisation: delivery_partner_user.organisation) }
  let!(:project) { create(:project_activity, parent: programme, organisation: delivery_partner_user.organisation, created_at: Date.today) }
  let!(:incomplete_project) { create(:project_activity, :at_geography_step, parent: programme, organisation: delivery_partner_user.organisation, created_at: Date.yesterday) }
  let!(:third_party_project) { create(:third_party_project_activity, parent: project, organisation: delivery_partner_user.organisation) }
  let!(:incomplete_third_party_project) { create(:third_party_project_activity, :at_region_step, parent: project, organisation: delivery_partner_user.organisation) }
  let!(:another_programme) { create(:programme_activity) }
  let!(:another_project) { create(:project_activity) }

  context "when signed in as a BEIS user" do
    context "when viewing the BEIS oganisation" do
      before do
        authenticate!(user: beis_user)
        visit organisation_path(beis_user.organisation)
      end

      scenario "they see a list of all projects" do
        within("##{project.id}") do
          expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
          expect(page).to have_content project.identifier
          expect(page).to have_content project.parent.title
        end

        within("##{another_project.id}") do
          expect(page).to have_link another_project.title, href: organisation_activity_path(another_project.organisation, another_project)
          expect(page).to have_content another_project.identifier
          expect(page).to have_content another_project.parent.title
        end
      end

      scenario "they see 'Incomplete' next to incomplete projects" do
        within("##{incomplete_project.id}") do
          expect(page).to have_link incomplete_project.title
          expect(page).to have_content I18n.t("summary.label.activity.form_state.incomplete")
        end
      end

      scenario "they see a Publish to Iati column & status against projects" do
        within(".projects") do
          expect(page).to have_content I18n.t("summary.label.activity.publish_to_iati.label")
        end

        within("##{project.id}") do
          expect(page).to have_content "Yes"
        end
      end

      scenario "they see a list of all third-party projects" do
        within("##{third_party_project.id}") do
          expect(page).to have_link third_party_project.title, href: organisation_activity_path(third_party_project.organisation, third_party_project)
          expect(page).to have_content third_party_project.identifier
          expect(page).to have_content third_party_project.parent.title
        end
      end

      scenario "they see 'Incomplete' next to incomplete third-party projects" do
        within("##{incomplete_third_party_project.id}") do
          expect(page).to have_link incomplete_third_party_project.title
          expect(page).to have_content I18n.t("summary.label.activity.form_state.incomplete")
        end
      end

      scenario "they see a Publish to Iati column & status against third-party projects" do
        within(".third-party-projects") do
          expect(page).to have_content I18n.t("summary.label.activity.publish_to_iati.label")
        end

        within("##{third_party_project.id}") do
          expect(page).to have_content "Yes"
        end
      end

      scenario "they see the organisation details" do
        expect(page).to have_content beis_user.organisation.name
        expect(page).to have_content beis_user.organisation.iati_reference
      end

      scenario "they see a edit details button" do
        expect(page).to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(beis_user.organisation)
      end
    end

    context "when viewing a delivery partners organisation" do
      scenario "they do not see funds or the create fund button" do
        visit organisation_path(delivery_partner_user.organisation)

        expect(page).not_to have_button I18n.t("page_content.organisation.button.create_activity")
        expect(page).not_to have_content "Funds"
      end
    end
  end

  context "when signed in as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
      visit organisation_path(delivery_partner_user.organisation)
    end

    scenario "they see a list of all their projects" do
      within("##{project.id}") do
        expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
        expect(page).to have_content project.identifier
        expect(page).to have_content project.parent.title
      end
    end

    scenario "the list of projects is ordered by created_at (oldest first)" do
      yet_another_project = create(:project_activity, organisation: delivery_partner_user.organisation, created_at: 2.days.ago)

      visit organisation_path(delivery_partner_user.organisation)

      expect(page.find("table.projects  tbody tr:first-child")[:id]).to have_content(yet_another_project.id)
      expect(page.find("table.projects  tbody tr:last-child")[:id]).to have_content(project.id)
    end

    scenario "they do not see a Publish to Iati column & status against projects" do
      within(".projects") do
        expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.label")
      end

      within("##{project.id}") do
        expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.yes")
      end
    end

    scenario "they do not see projects that they are not the reporting organisation of" do
      expect(page).not_to have_content another_project.identifier
    end

    scenario "they see a list of all their third-party projects" do
      within("##{third_party_project.id}") do
        expect(page).to have_link third_party_project.title, href: organisation_activity_path(third_party_project.organisation, third_party_project)
        expect(page).to have_content third_party_project.identifier
        expect(page).to have_content third_party_project.parent.title
      end
    end

    scenario "they do not see a Publish to Iati column & status against third-party projects" do
      within(".third-party-projects") do
        expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.label")
      end

      within("##{third_party_project.id}") do
        expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.yes")
      end
    end

    scenario "they do not see third-party projects that belong to another organisation" do
      other_third_party_project = create(:third_party_project_activity, organisation: create(:delivery_partner_organisation))

      expect(page).to_not have_content(other_third_party_project.title)
    end

    scenario "they do not see the edit detials button" do
      expect(page).not_to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(delivery_partner_user.organisation)
    end
  end
end
