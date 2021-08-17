RSpec.describe "Users can search for activities" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  let!(:project) { create(:programme_activity, roda_identifier: "roda-id", title: "Project A") }

  before do
    visit "/"
    fill_in :query, with: "roda-id"
    click_button t("form.activity_search.submit")
  end

  scenario "searching by RODA identifier" do
    expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)

    within ".govuk-breadcrumbs" do
      expect(page).to have_content("Home")
      expect(page).to have_content("Search results for “roda-id”")
    end
  end

  scenario "user sees breadcrumb context when accessing an activity from search results" do
    click_on project.title

    within ".govuk-breadcrumbs" do
      expect(page).to have_content("Home")
      expect(page).to have_content("Search results for “roda-id”")
      expect(page).to have_content(project.title)
    end
  end
end
