RSpec.feature "Users can create a project" do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner) { create(:delivery_partner_organisation) }

  context "when an administrator" do
    before { authenticate!(user: create(:administrator, organisation: delivery_partner)) }

    context "when viewing a programme" do
      scenario "a new project can be added to the programme" do
        fund = create(:fund_activity, organisation: beis)
        programme = create(:programme_activity, organisation: beis)
        fund.activities << programme

        visit organisation_activity_path(programme.organisation, programme)

        expect(page).to have_content programme.title
        click_on(I18n.t("page_content.organisation.button.create_project"))

        fill_in_activity_form

        expect(page).to have_content I18n.t("form.project.create.success")
        expect(programme.activities.count).to eq 1

        project = programme.activities.last

        expect(project.organisation).to eq beis
      end
    end
  end
end
