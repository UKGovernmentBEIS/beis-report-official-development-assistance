RSpec.feature "Users can create a project" do
  context "when they are a delivery parther" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a programme" do
      scenario "a new project cannot be added to the programme when a report does not exist" do
        programme_activity = create(:programme_activity, :newton_funded, extending_organisation: user.organisation)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)
        click_on t("tabs.activity.children")

        expect(page).to have_no_button(t("action.activity.add_child"))
      end

      scenario "a new project can be added to the programme" do
        programme = create(:programme_activity, :newton_funded, extending_organisation: user.organisation)
        report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit activities_path
        click_on programme.title
        click_on t("tabs.activity.children")
        click_on t("action.activity.add_child")

        fill_in_activity_form(level: "project", parent: programme)

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        project = programme.child_activities.last

        expect(project.organisation).to eq user.organisation

        # our new direct association between activity and report
        expect(project.originating_report).to eq(report)
        expect(report.new_activities).to eq([project])
      end

      scenario "can create a new child activity for a given programme" do
        gcrf = create(:fund_activity, :gcrf)
        programme = create(:programme_activity, parent: gcrf, extending_organisation: user.organisation)
        _report = create(:report, :active, fund: gcrf, organisation: user.organisation)

        visit organisation_activity_path(programme.organisation, programme)

        click_link t("tabs.activity.children")
        click_button t("action.activity.add_child")
        fill_in "activity[delivery_partner_identifier]", with: "foo"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.purpose", level: "project (level C)")
      end

      scenario "a new project can be added when the program has no RODA identifier" do
        programme = create(:programme_activity, :newton_funded, extending_organisation: user.organisation, roda_identifier: nil)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.extending_organisation, programme)
        click_on t("action.activity.add_child")

        fill_in_activity_form(level: "project", parent: programme)

        expect(page).to have_content t("action.project.create.success")

        expect(programme.child_activities.count).to eq 1
        project = programme.child_activities.last
        expect(project.organisation).to eq user.organisation
      end

      scenario "the activity saves its identifier as read-only `transparency_identifier`" do
        programme = create(:programme_activity, :newton_funded, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.extending_organisation, programme)
        click_on t("action.activity.add_child")

        fill_in_activity_form(level: "project", parent: programme)

        activity = Activity.order("created_at ASC").last
        expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.roda_identifier}")
      end

      scenario "the activity date shows an error message if an invalid date is entered" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.extending_organisation, programme)
        click_on t("action.activity.add_child")

        fill_in "activity[delivery_partner_identifier]", with: "no-country-selected"
        click_button t("form.button.activity.submit")
        fill_in "activity[title]", with: "My title"
        fill_in "activity[description]", with: "My description"
        click_button t("form.button.activity.submit")
        fill_in "activity[objectives]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")
        choose "Basic Education"
        click_button t("form.button.activity.submit")
        choose "School feeding"
        click_button t("form.button.activity.submit")
        choose "No"
        click_button t("form.button.activity.submit")
        choose "Delivery"
        click_button t("form.button.activity.submit")
        fill_in "activity[planned_start_date(3i)]", with: "01"
        fill_in "activity[planned_start_date(2i)]", with: "12"
        fill_in "activity[planned_start_date(1i)]", with: "2020"
        fill_in "activity[planned_end_date(3i)]", with: "01"
        fill_in "activity[planned_end_date(2i)]", with: "15"
        fill_in "activity[planned_end_date(1i)]", with: "2021"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_end_date.invalid")
      end

      context "when creating a project that is Newton funded" do
        let(:newton_fund) { create(:fund_activity, :newton) }

        scenario "'country_delivery_partners' can be present" do
          newton_programme = create(:programme_activity, extending_organisation: user.organisation, parent: newton_fund)
          _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)

          visit organisation_activity_children_path(newton_programme.extending_organisation, newton_programme)
          click_on t("action.activity.add_child")

          fill_in_activity_form(level: "project", parent: newton_programme)

          expect(page).to have_content t("action.project.create.success")
          activity = Activity.order("created_at ASC").last
          expect(activity.country_delivery_partners).to eql(["National Council for the State Funding Agencies (CONFAP)"])
        end

        scenario "'country_delivery_partners' is however not mandatory for Newton funded projects" do
          newton_programme = create(:programme_activity, extending_organisation: user.organisation, parent: newton_fund)
          _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)

          visit organisation_activity_children_path(newton_programme.extending_organisation, newton_programme)
          click_on t("action.activity.add_child")

          fill_in_activity_form(level: "project", parent: newton_programme, country_delivery_partners: nil)

          expect(page).to have_content t("action.project.create.success")
          activity = Activity.order("created_at ASC").last
          expect(activity.country_delivery_partners).to be_empty
        end
      end
    end
  end
end
