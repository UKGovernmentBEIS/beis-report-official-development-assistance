RSpec.feature "Users can manage the implementing organisations" do
  context "when they are signed in as a partner organisation user" do
    let(:partner_organisation) { create(:delivery_partner_organisation) }
    let(:project) { create(:project_activity, organisation: partner_organisation) }
    let!(:report) { create(:report, :active, organisation: partner_organisation, fund: project.associated_fund) }

    let!(:implementing_org) do
      create(
        :implementing_organisation,
        name: "Implementing org",
        iati_reference: "GB-COH-123456"
      ).tap do |org|
        OrgParticipation.create(
          organisation: org,
          activity: create(:project_activity),
          role: "implementing"
        )
      end
    end

    let!(:other_implementing_org) do
      create(
        :implementing_organisation,
        name: "Another implementing org",
        iati_reference: "GB-COH-654321"
      ).tap do |org|
        OrgParticipation.create(
          organisation: org,
          activity: create(:project_activity),
          role: "implementing"
        )
      end
    end

    before do
      authenticate!(
        user: create(:delivery_partner_user, organisation: partner_organisation)
      )
      create(:delivery_partner_organisation, name: "Another partner organisation")
    end

    scenario "they can add an implementing org from a list of all organisations" do
      def then_i_see_a_list_containing_all_organisations
        expect(page).to have_select(
          t("form.label.implementing_organisation"),
          options: Organisation.sorted_by_name.pluck(:name)
        )
      end

      def then_i_see_guidance_about_adding_to_this_list
        expect(page).to have_content(
          t("form.guidance_html", link: "support@beisodahelp.zendesk.com")
        )
      end

      def when_i_select_the_implementing_organisation(name)
        select(name, from: t("form.label.implementing_organisation"))
      end

      def then_i_see_that_the_implementing_org_was_added(implementing_org)
        expect(current_path).to eq organisation_activity_details_path(project.organisation, project)
        expect(page).to have_content t("action.implementing_organisation.create.success")

        expect(page).to have_content implementing_org.name
        expect(page).to have_content implementing_org.iati_reference
      end

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content t("page_content.activity.implementing_organisation.button.new")
      click_on t("page_content.activity.implementing_organisation.button.new")

      then_i_see_a_list_containing_all_organisations
      then_i_see_guidance_about_adding_to_this_list
      when_i_select_the_implementing_organisation("Implementing org")

      click_on t("default.button.submit")

      then_i_see_that_the_implementing_org_was_added(implementing_org)
    end

    scenario "they can remove an implementing org from a list of associated ones" do
      def given_the_project_has_two_implementing_orgs
        project.implementing_organisations = [implementing_org, other_implementing_org]
      end

      def when_i_delete_the_second_implementing_org
        visit organisation_activity_details_path(project.organisation, project)
        expect(page).to have_css(".implementing_organisation", count: 2)

        within(all(".implementing_organisation").last) do
          click_on "Remove"
        end
      end

      def then_i_see_only_the_first_org_associated_with_the_project
        expect(page).to have_content(
          t("action.implementing_organisation.delete.success")
        )
        expect(page).to have_css(".implementing_organisation", count: 1)
      end

      given_the_project_has_two_implementing_orgs
      when_i_delete_the_second_implementing_org
      then_i_see_only_the_first_org_associated_with_the_project
    end
  end

  context "when they are signed in as a BEIS user" do
    let(:partner_organisation) { create(:delivery_partner_organisation) }
    let(:project) { create(:project_activity, organisation: partner_organisation) }

    before { authenticate!(user: create(:beis_user)) }

    scenario "they can view implementing organisations" do
      other_public_sector_organisation = create(:implementing_organisation, name: "Other public sector organisation", organisation_type: "70", iati_reference: "GB-COH-123456")
      project.implementing_organisations << other_public_sector_organisation

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content other_public_sector_organisation.name
      expect(page).to have_content other_public_sector_organisation.iati_reference
    end

    scenario "they cannot remove implementing organisations" do
      other_public_sector_organisation = create(:implementing_organisation, name: "Other public sector organisation", organisation_type: "70", iati_reference: "GB-COH-123456")
      project.implementing_organisations << other_public_sector_organisation

      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_link("Remove")
    end

    scenario "they cannot add implementing organisations" do
      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_button t("page_content.activity.implementing_organisation.button.new")
    end
  end
end
