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

    context "when viewing a single activity" do
      let(:user) { create(:delivery_partner_user) }

      before do
        authenticate!(user: user)
      end

      scenario "they do not see a Publish to Iati column & status against projects" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        project = create(:project_activity, organisation: user.organisation, parent: programme)

        visit organisation_activity_path(user.organisation.id, project)

        click_on t("tabs.activity.details")
        click_on programme.title
        click_on t("tabs.activity.children")

        expect(page).to_not have_content t("summary.label.activity.publish_to_iati.label")

        within("##{project.id}") do
          expect(page).to_not have_content t("summary.label.activity.publish_to_iati.true")
        end
      end

      scenario "the activity financials can be viewed" do
        activity = create(:project_activity, organisation: user.organisation)
        transaction = create(:transaction, parent_activity: activity)
        budget = create(:budget, parent_activity: activity)

        visit organisation_activity_financials_path(activity.organisation, activity)
        within ".govuk-tabs__list-item--selected" do
          expect(page).to have_content "Financials"
        end
        expect(page).to have_content transaction.value
        expect(page).to have_content budget.value
      end

      scenario "an activity can be viewed" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        activity = create(:project_activity, parent: programme, organisation: user.organisation, sdgs_apply: true, sdg_1: 5)

        visit organisation_activity_details_path(activity.organisation, activity)

        click_on(programme.title)
        click_on t("tabs.activity.children")
        click_on activity.title
        click_on t("tabs.activity.details")

        activity_presenter = ActivityPresenter.new(activity)

        expect(page).to have_content activity_presenter.roda_identifier
        expect(page).to have_content activity_presenter.sector
        expect(page).to have_content activity_presenter.title
        expect(page).to have_content activity_presenter.description
        expect(page).to have_content activity_presenter.planned_start_date
        expect(page).to have_content activity_presenter.planned_end_date
        expect(page).to have_content activity_presenter.recipient_region

        within ".sustainable_development_goals" do
          expect(page).to have_content "Gender Equality"
        end
      end
    end
  end
end
