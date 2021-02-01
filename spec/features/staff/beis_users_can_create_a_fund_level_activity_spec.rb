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
      fill_in_activity_form(delivery_partner_identifier: identifier, level: "fund")
      activity = Activity.find_by(delivery_partner_identifier: identifier)
      expect(activity.programme_status).to eq("spend_in_progress")
    end

    scenario "the activity form has some defaults" do
      activity = create(:fund_activity, organisation: user.organisation)
      activity_presenter = ActivityPresenter.new(activity)
      visit activities_path

      click_on t("page_content.organisation.button.create_activity")

      visit activity_step_path(activity, :region)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      identifier = "a-fund-has-an-accountable-organisation"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(delivery_partner_identifier: identifier, level: "fund")

      activity = Activity.find_by(delivery_partner_identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate extending organisation defaults" do
      identifier = "a-fund-has-an-extending-organisation"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(delivery_partner_identifier: identifier, level: "fund")

      activity = Activity.find_by(delivery_partner_identifier: identifier)
      expect(activity.extending_organisation).to eql(user.organisation)
    end

    scenario "the activity saves its identifier as read-only `transparency_identifier`" do
      identifier = "a-fund"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(roda_identifier_fragment: identifier, level: "fund")

      activity = Activity.find_by(roda_identifier_fragment: identifier)
      expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.roda_identifier_fragment}")
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
        _another_activity = create(:activity, delivery_partner_identifier: identifier)
        new_activity = create(:activity, :blank_form_state, organisation: user.organisation)

        visit activity_step_path(new_activity, :identifier)

        fill_in "activity[delivery_partner_identifier]", with: identifier
        click_button t("form.button.activity.submit")

        expect(page).to have_content "has already been taken"
      end
    end

    context "validations" do
      scenario "validation errors work as expected" do
        identifier = "GCRF"

        visit activities_path
        click_on t("page_content.organisation.button.create_activity")

        # Don't provide a level
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.level.blank")

        choose "Fund"
        click_button t("form.button.activity.submit")

        # Skip the parent step, and instead goto the delivery partner identifier step
        expect(page).to have_no_content t("form.legend.activity.parent")
        expect(page).to have_content t("form.label.activity.delivery_partner_identifier")

        # Don't provide an identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.delivery_partner_identifier.blank")

        fill_in "activity[delivery_partner_identifier]", with: identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.roda_identifier_fragment", level: "fund")

        # Provide an invalid identifier
        fill_in "activity[roda_identifier_fragment]", with: "!!!"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.roda_identifier_fragment.invalid_characters")

        fill_in "activity[roda_identifier_fragment]", with: identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content custom_capitalisation(t("form.legend.activity.purpose", level: "fund (level A)"))
        expect(page).to have_content t("form.hint.activity.title", level: "fund (level A)")

        # Don't provide a title and description
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("activerecord.errors.models.activity.attributes.title.blank")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.description.blank")

        fill_in "activity[title]", with: Faker::Lorem.word
        fill_in "activity[description]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector_category", level: "fund (level A)")

        # Don't provide a sector category
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector_category.blank")

        choose "Basic Education"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector", sector_category: "Basic Education", level: "fund (level A)")
        # Don't provide a sector
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector.blank")

        choose "Primary education"
        click_button t("form.button.activity.submit")

        # Skip the programme_status step, and go straight to the date step
        expect(page).to have_no_content t("form.legend.activity.programme_status", level: "fund (level A)")
        expect(page).to have_content t("page_title.activity_form.show.dates", level: "fund (level A)")

        # Dates cannot contain only a zero
        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 0
        fill_in "activity[planned_start_date(1i)]", with: 2010
        fill_in "activity[planned_end_date(3i)]", with: 0
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2010
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_start_date.invalid")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_end_date.invalid")

        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 12
        fill_in "activity[planned_start_date(1i)]", with: 2020
        fill_in "activity[planned_end_date(3i)]", with: 1
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2020
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.geography")

        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.geography.blank")

        choose "Region"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.recipient_region")

        # region has the default value already selected
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")

        # Don't select any option
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.requires_additional_benefitting_countries.blank")

        choose "Yes"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.intended_beneficiaries")

        # Don't select any intended beneficiaries
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.intended_beneficiaries.blank")

        check "Haiti"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.gdi")

        # Don't select a GDI
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.gdi.blank")

        choose "GDI not applicable"
        click_button t("form.button.activity.submit")

        # Skip the collaboration type step
        expect(page).to have_no_content t("form.label.activity.collaboration_type")

        # Skip the SDGs step and instead go to the aid type step
        expect(page).to have_no_content t("form.legend.activity.sdgs_apply")
        expect(page).to have_content t("form.legend.activity.aid_type")

        # Don't select an aid type
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.aid_type.blank")

        choose("activity[aid_type]", option: "B02")
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.fstc_applies")

        # Don't choose if fstc applies or not
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.fstc_applies.inclusion")

        choose("activity[fstc_applies]", option: true)
        click_button t("form.button.activity.submit")

        # Covid19-related has a default and can't be set to blank so we skip
        click_button t("form.button.activity.submit")

        # Skip the GCRF challenge area step, and instead go to the oda_eligibility step
        expect(page).to have_no_content t("form.legend.activity.gcrf_challenge_area")
        expect(page).to have_content t("form.legend.activity.oda_eligibility")

        # oda_eligibility has the default value already selected
        click_button t("form.button.activity.submit")

        # Skip the oda_eligibility_lead step
        expect(page).to have_no_content t("form.hint.activity.oda_eligibility_lead")

        # Form completed
        expect(page).to have_content Activity.find_by(delivery_partner_identifier: identifier).title
      end

      scenario "failing to select a country shows an error message" do
        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        choose custom_capitalisation(t("page_content.activity.level.fund"))
        click_button t("form.button.activity.submit")
        fill_in "activity[delivery_partner_identifier]", with: "no-country-selected"
        click_button t("form.button.activity.submit")
        fill_in "activity[roda_identifier_fragment]", with: "roda-identifier"
        click_button t("form.button.activity.submit")
        fill_in "activity[title]", with: "My title"
        fill_in "activity[description]", with: "My description"
        click_button t("form.button.activity.submit")
        choose "Basic Education"
        click_button t("form.button.activity.submit")
        choose "School feeding"
        click_button t("form.button.activity.submit")
        fill_in "activity[planned_start_date(3i)]", with: "01"
        fill_in "activity[planned_start_date(2i)]", with: "01"
        fill_in "activity[planned_start_date(1i)]", with: "2020"
        click_button t("form.button.activity.submit")
        choose "Country"
        click_button t("form.button.activity.submit")
        click_button t("form.button.activity.submit")
        expect(page).to have_content "Recipient country can't be blank"
      end
    end

    scenario "fund creation is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit activities_path
        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "fund", delivery_partner_identifier: "my-unique-identifier")

        fund = Activity.find_by(delivery_partner_identifier: "my-unique-identifier")
        auditable_events = PublicActivity::Activity.where(trackable_id: fund.id)
        expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.aid_type")
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
