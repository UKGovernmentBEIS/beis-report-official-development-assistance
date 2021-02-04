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

      scenario "the activity date shows an error message if an invalid date is entered" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        visit organisation_activity_children_path(programme.organisation, programme)

        click_on(t("page_content.organisation.button.create_activity"))
        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        choose custom_capitalisation(t("page_content.activity.level.project"))
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.parent", parent_level: t("page_content.activity.level.programme", level: "programme"), level: t("page_content.activity.level.programme"))
        expect(page).to have_content t("form.hint.activity.parent", parent_level: t("page_content.activity.level.programme"), level: t("page_content.activity.level.project"))
        choose programme.title
        click_button t("form.button.activity.submit")
        fill_in "activity[delivery_partner_identifier]", with: "no-country-selected"
        click_button t("form.button.activity.submit")
        fill_in "activity[roda_identifier_fragment]", with: "roda-identifier"
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

      scenario "project creation is tracked with public_activity" do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

        PublicActivity.with_tracking do
          visit organisation_activity_children_path(programme.organisation, programme)
          click_on(t("page_content.organisation.button.create_activity"))

          fill_in_activity_form(level: "project", delivery_partner_identifier: "my-unique-identifier", parent: programme)

          project = Activity.find_by(delivery_partner_identifier: "my-unique-identifier")
          auditable_events = PublicActivity::Activity.where(trackable_id: project.id)
          expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.aid_type")
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

      context "when the aid type is one of 'D02', 'E01', 'G01'" do
        it "skips the FSTC applies step and infers it from the aid type" do
          programme = create(:programme_activity, extending_organisation: user.organisation)
          _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

          visit organisation_activity_children_path(programme.organisation, programme)
          click_on(t("page_content.organisation.button.create_activity"))

          # Test is done in this method:
          fill_in_activity_form(level: "project", parent: programme, aid_type: "D02")

          expect(page).to have_content t("action.project.create.success")
          expect(programme.child_activities.last.fstc_applies).to eql true
        end
      end

      context "when the aid type is 'C01'" do
        it "pre-selects Yes for the FSTC applies step but lets the user choose" do
          programme = create(:programme_activity, extending_organisation: user.organisation)
          _report = create(:report, state: :active, organisation: user.organisation, fund: programme.associated_fund)

          visit organisation_activity_children_path(programme.organisation, programme)
          click_on(t("page_content.organisation.button.create_activity"))

          # Test is done in this method:
          fill_in_activity_form(level: "project", parent: programme, aid_type: "C01", fstc_applies: false)

          expect(page).to have_content t("action.project.create.success")
          expect(programme.child_activities.last.fstc_applies).to eql false
        end
      end
    end
  end
end
