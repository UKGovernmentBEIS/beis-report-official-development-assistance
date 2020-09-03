RSpec.describe "Users can edit a planned disbursement" do
  context "when signed in as a deivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can edit a planned disbursement" do
      organisation = user.organisation
      project = create(:project_activity, :with_report, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: project)
      visit organisation_activity_path(organisation, project)

      within "##{planned_disbursement.id}" do
        click_on "Edit"
      end

      expect(page).to have_http_status(:success)

      fill_in "Receiving organisation", with: "An Organisation"
      click_button "Submit"

      expect(page).to have_content t("action.planned_disbursement.update.success")
      expect(page).to have_content "An Organisation"
    end

    scenario "the action is recorded with public_activity" do
      PublicActivity.with_tracking do
        project = create(:project_activity, :with_report, organisation: user.organisation)
        planned_disbursement = create(:planned_disbursement, parent_activity: project)

        visit activities_path
        click_on(project.title)
        within("##{planned_disbursement.id}") do
          click_on(t("default.link.edit"))
        end

        fill_in_planned_disbursement_form(value: "2000.51")

        auditable_event = PublicActivity::Activity.find_by(trackable_id: planned_disbursement.id)
        expect(auditable_event.key).to eq "planned_disbursement.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end
  end
end
