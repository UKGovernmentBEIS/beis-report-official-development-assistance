RSpec.feature "Users can create a fund level activity" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit activity_step_path(double(Activity, id: "123"), :identifier)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "successfully create a activity" do
      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "fund")

      expect(page).to have_content t("action.fund.create.success")
    end

    scenario "a default value of 'Spend in progress' for programme status gets set" do
      identifier = "a-fund-with-default-programme-status-of-spend-in-progress"
      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))
      fill_in_activity_form(identifier: identifier, level: "fund")
      activity = Activity.find_by(identifier: identifier)
      expect(activity.programme_status).to eq("07")
    end

    scenario "the iati status gets set based on the default programme status value" do
      identifier = "a-fund-with-default-iati-status-of-implementation"
      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))
      fill_in_activity_form(identifier: identifier, level: "fund")
      activity = Activity.find_by(identifier: identifier)
      expect(activity.status).to eq("2")
    end

    scenario "the activity form has some defaults" do
      activity = create(:fund_activity, organisation: user.organisation)
      activity_presenter = ActivityPresenter.new(activity)
      visit activities_path

      click_on t("page_content.organisation.button.create_activity")

      visit activity_step_path(activity, :region)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region

      visit activity_step_path(activity, :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.flow
    end

    scenario "the activity has the appropriate funding organisation defaults" do
      identifier = "a-fund-has-a-funding-organisation"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.funding_organisation_name).to eq("HM Treasury")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-2")
      expect(activity.funding_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      identifier = "a-fund-has-an-accountable-organisation"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate extending organisation defaults" do
      identifier = "a-fund-has-an-extending-organisation"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.extending_organisation).to eql(user.organisation)
    end

    scenario "the activity saves its identifier as read-only `transparency_identifier`" do
      identifier = "a-fund"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.identifier}")
    end

    context "when there is an existing activity with a nil identifier" do
      scenario "successfully create a activity" do
        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "fund")

        expect(page).to have_content t("action.fund.create.success")
      end
    end

    context "when there is an existing activity with the same identifier" do
      scenario "cannot use the duplicate identifier" do
        identifier = "A-non-unique-identifier"
        _another_activity = create(:activity, identifier: identifier)
        new_activity = create(:activity, :blank_form_state, organisation: user.organisation)

        visit activity_step_path(new_activity, :identifier)

        fill_in "activity[identifier]", with: identifier
        click_button t("form.button.activity.submit")

        expect(page).to have_content "has already been taken"
      end
    end

    context "validations" do
      scenario "validation errors work as expected" do
        parent = create(:fund_activity, organisation: user.organisation)
        identifier = "foo"

        visit activities_path
        click_on t("page_content.organisation.button.create_activity")

        # Don't provide a level
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.level.blank")

        choose "Programme"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.parent")

        # Don't provide a parent
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.parent.blank")

        choose parent.title
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.identifier")

        # Don't provide an identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.identifier.blank")

        fill_in "activity[identifier]", with: identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.purpose", level: "programme")
        expect(page).to have_content t("form.hint.activity.title", level: "programme")

        # Don't provide a title and description
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("activerecord.errors.models.activity.attributes.title.blank")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.description.blank")

        fill_in "activity[title]", with: Faker::Lorem.word
        fill_in "activity[description]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector_category", level: "programme")

        # Don't provide a sector category
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector_category.blank")

        choose "Basic Education"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector", sector_category: "Basic Education", level: "programme")
        # Don't provide a sector
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector.blank")

        choose "Primary education"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.programme_status", level: "programme")

        # Don't provide a programme status
        click_button t("form.button.activity.submit")
        expect(page).to have_content "can't be blank"

        choose("activity[programme_status]", option: "07")
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("page_title.activity_form.show.dates", level: "programme")

        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.dates")

        # Dates cannot contain only a zero
        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 0
        fill_in "activity[planned_start_date(1i)]", with: 2010
        fill_in "activity[planned_end_date(3i)]", with: 0
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2010
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("activerecord.errors.models.activity.attributes.dates")

        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 12
        fill_in "activity[planned_start_date(1i)]", with: 2010
        fill_in "activity[planned_end_date(3i)]", with: 1
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2010
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.geography")

        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.geography.blank")

        choose "Region"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.recipient_region")

        # region has the default value already selected
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.label.activity.flow")

        # Flow has a default and can't be set to blank so we skip
        select "ODA", from: "activity[flow]"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.aid_type")

        # Don't select an aid type
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.aid_type.blank")

        choose("activity[aid_type]", option: "A01")
        click_button t("form.button.activity.submit")
        expect(page).to have_content Activity.find_by(identifier: identifier).title
      end
    end

    scenario "fund creation is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "fund", identifier: "my-unique-identifier")

        fund = Activity.find_by(identifier: "my-unique-identifier")
        auditable_events = PublicActivity::Activity.where(trackable_id: fund.id)
        expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
        expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
        expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [fund.id]
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    it "does not allow them to see funds" do
      fund_activity = create(:fund_activity)

      visit organisation_path(user.organisation)

      expect(page).not_to have_content(fund_activity.title)
    end

    it "does not let them create a fund level activity" do
      visit organisation_path(user.organisation)
      expect(page).not_to have_button(t("page_content.organisation.button.create_activity"))
    end
  end
end
