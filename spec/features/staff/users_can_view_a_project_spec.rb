RSpec.feature "Users can view a project" do
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  let(:beis) { create(:beis_organisation) }

  context "when an signed in as an administrator" do
    before { authenticate!(user: create(:administrator, organisation: beis)) }

    scenario "can view a project" do
      fund = create(:fund_activity, organisation: beis)
      programme = create(:programme_activity, organisation: beis)
      fund.activities << programme
      project = create(:project_activity, organisation: delivery_partner)
      programme.activities << project

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content project.title
    end

    context "when viewing a programme" do
      scenario "links to the programmes projects" do
        fund = create(:fund_activity, organisation: beis)
        programme = create(:programme_activity, organisation: beis)
        fund.activities << programme
        project = create(:project_activity, organisation: delivery_partner)
        programme.activities << project

        visit organisation_activity_path(programme.organisation, programme)

        expect(page).to have_content programme.title

        click_on project.title

        expect(page).to have_content project.title
      end
    end
  end
end
