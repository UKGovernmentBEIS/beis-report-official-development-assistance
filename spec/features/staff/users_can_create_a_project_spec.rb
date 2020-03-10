RSpec.feature "Users can create a project" do
  let(:beis) { create(:delivery_partner_organisation) }

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a programme" do
      scenario "a new project can be added to the programme" do
        programme = create(:programme_activity)

        visit organisation_path(user.organisation)

        click_on(programme.title)

        click_on(I18n.t("page_content.organisation.button.create_project"))

        fill_in_activity_form(level: "project")

        expect(page).to have_content I18n.t("form.project.create.success")
        expect(programme.activities.count).to eq 1

        project = programme.activities.last

        expect(project.organisation).to eq user.organisation
      end
    end
  end
end
