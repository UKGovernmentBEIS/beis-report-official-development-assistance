RSpec.describe "Users can search for activities" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  let!(:project) { create(:programme_activity, roda_identifier_fragment: "roda-id", title: "Project A") }
  let!(:third_party_project) { create(:third_party_project_activity, roda_identifier_fragment: "roda-id", title: "Third-party Project B") }

  scenario "searching by RODA identifier fragment" do
    visit "/"
    fill_in :query, with: "roda-id"
    click_button t("form.activity_search.submit")

    expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
    expect(page).to have_link third_party_project.title, href: organisation_activity_path(third_party_project.organisation, third_party_project)
  end
end
