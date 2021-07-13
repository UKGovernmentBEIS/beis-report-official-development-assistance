RSpec.feature "Users can view activities" do
  shared_examples "shows activities" do |params|
    let(:user) { create(params[:user_type]) }
    let(:organisation) { params[:user_type] == :beis_user ? create(:delivery_partner_organisation) : user.organisation }

    let!(:fund) { create(:fund_activity, :newton) }
    let!(:programme) { create(:programme_activity, parent: fund, extending_organisation: organisation) }
    let!(:project) { create(:project_activity, parent: programme, extending_organisation: organisation) }
    let!(:third_party_projects) { create_list(:third_party_project_activity, 3, parent: project, extending_organisation: organisation) }

    let!(:historic_programme) { create(:programme_activity, parent: fund, extending_organisation: organisation, programme_status: "completed") }

    before do
      authenticate!(user: user)
    end

    scenario "they can see and navigate current activities", js: true do
      visit activities_path

      expect(page).to have_content t("page_title.activity.index")

      expect(page).to have_css(".govuk-tabs__tab", count: 2)
      expect(page).to have_css(".govuk-tabs__tab", text: "Current")
      expect(page).to have_css(".govuk-tabs__tab", text: "Historic")

      expect(page).to have_content(programme.title)
      expect(page).to have_content(programme.roda_identifier)

      expect(page).to_not have_content(historic_programme.roda_identifier)

      expect(page).not_to have_css("#activity-#{project.id}", visible: true)
      third_party_projects.each do |third_party_project|
        expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)
      end

      click_on programme.title
      expect(page).to have_css("#activity-#{project.id}", visible: true)

      third_party_projects.each do |third_party_project|
        expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)
      end

      click_on project.title
      expect(page).to have_css("#activity-#{project.id}", visible: true)

      third_party_projects.each do |third_party_project|
        expect(page).to have_css("#activity-#{third_party_project.id}", visible: true)
      end

      # Users can hide the expanded rows by clicking the parent activity
      click_on programme.title
      expect(page).not_to have_css("#activity-#{project.id}", visible: true)

      third_party_projects.each do |third_party_project|
        expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)
      end
    end

    scenario "they can see historic activities" do
      visit historic_activities_path

      expect(page).to have_content t("page_title.activity.index")

      expect(page).to have_content(historic_programme.title)
    end
  end

  context "when the user is signed in as a BEIS user" do
    include_examples "shows activities", {
      user_type: :beis_user,
    }

    scenario "only delivery partners are listed" do
      delivery_partners = create_list(:delivery_partner_organisation, 3)
      matched_effort_provider = create(:matched_effort_provider)
      external_income_provider = create(:external_income_provider)

      visit activities_path(organisation_id: user.organisation)

      within "select#organisation_id" do
        delivery_partners.each do |delivery_partner|
          expect(page).to have_content(delivery_partner.name)
        end

        expect(page).to_not have_content(matched_effort_provider.name)
        expect(page).to_not have_content(external_income_provider.name)
      end
    end
  end

  context "when the user is signed in as a delivery partner" do
    context "when viewing the activities index page" do
      include_examples "shows activities", {
        user_type: :delivery_partner_user,
      }
    end
  end
end
