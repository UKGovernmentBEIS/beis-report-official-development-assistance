RSpec.describe "Users can search for activities" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  let!(:project) { create(:programme_activity, roda_identifier: "roda-id", title: "Project A") }

  scenario "searching by RODA identifier" do
    visit "/"
    fill_in :query, with: "roda-id"
    click_button t("form.activity_search.submit")

    expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
  end
end
