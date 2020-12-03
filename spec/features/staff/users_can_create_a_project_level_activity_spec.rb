RSpec.feature "Users can create a project" do
  let(:beis) { create(:delivery_partner_organisation) }

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a programme" do
      scenario "a new project can be added to the programme" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.organisation, programme)

        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "project", parent: programme)

        expect(page).to have_content t("action.project.create.success")
        expect(programme.child_activities.count).to eq 1

        project = programme.child_activities.last

        expect(project.organisation).to eq user.organisation
      end

      scenario "a new project can be added when the program has no RODA identifier" do
        programme = create(:programme_activity, extending_organisation: user.organisation, roda_identifier_fragment: nil)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.organisation, programme)
        click_on(t("page_content.organisation.button.create_activity"))
        fill_in_activity_form(level: "project", parent: programme)

        expect(page).to have_content t("action.project.create.success")

        expect(programme.child_activities.count).to eq 1
        project = programme.child_activities.last
        expect(project.organisation).to eq user.organisation
      end

      scenario "the activity saves its identifier as read-only `transparency_identifier`" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)
        identifier = "a-project"

        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(roda_identifier_fragment: identifier, level: "project", parent: programme)

        activity = Activity.find_by(roda_identifier_fragment: identifier)
        expect(activity.transparency_identifier).to eql("GB-GOV-13-#{programme.parent.roda_identifier_fragment}-#{programme.roda_identifier_fragment}-#{activity.roda_identifier_fragment}")
      end

      scenario "project creation is tracked with public_activity" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        PublicActivity.with_tracking do
          visit organisation_activity_children_path(programme.organisation, programme)
          click_on(t("page_content.organisation.button.create_activity"))

          fill_in_activity_form(level: "project", delivery_partner_identifier: "my-unique-identifier", parent: programme)

          project = Activity.find_by(delivery_partner_identifier: "my-unique-identifier")
          auditable_events = PublicActivity::Activity.where(trackable_id: project.id)
          expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
          expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
          expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [project.id]
        end
      end

      context "when creating a project that is Newton funded" do
        scenario "'country_delivery_partners' can be present" do
          newton_fund = create(:fund_activity, :newton, organisation: user.organisation)
          newton_programme = create(:programme_activity, extending_organisation: user.organisation, parent: newton_fund)
          _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)
          identifier = "newton-project"

          visit activities_path
          click_on(t("page_content.organisation.button.create_activity"))

          fill_in_activity_form(level: "project", roda_identifier_fragment: identifier, parent: newton_programme)

          expect(page).to have_content t("action.project.create.success")
          activity = Activity.find_by(roda_identifier_fragment: identifier)
          expect(activity.country_delivery_partners).to eql(["National Council for the State Funding Agencies (CONFAP)"])
        end

        scenario "'country_delivery_partners' is however not mandatory for Newton funded projects" do
          newton_fund = create(:fund_activity, :newton, organisation: user.organisation)
          newton_programme = create(:programme_activity, extending_organisation: user.organisation, parent: newton_fund)
          _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)
          identifier = "newton-project"

          visit activities_path
          click_on(t("page_content.organisation.button.create_activity"))

          fill_in_activity_form(level: "project", roda_identifier_fragment: identifier, parent: newton_programme, country_delivery_partners: nil)

          expect(page).to have_content t("action.project.create.success")
          activity = Activity.find_by(roda_identifier_fragment: identifier)
          expect(activity.country_delivery_partners).to be_empty
        end
      end
    end
  end
end
