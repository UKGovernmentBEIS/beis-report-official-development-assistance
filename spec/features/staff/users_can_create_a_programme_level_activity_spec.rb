RSpec.feature "Users can create a programme activity" do
  let(:user) { create(:beis_user) }

  context "when signed in" do
    before do
      authenticate!(user: user)
    end

    scenario "successfully creates a programme" do
      fund = create(:fund_activity, organisation: user.organisation)

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "programme", parent: fund)

      expect(page).to have_content t("action.programme.create.success")
    end

    context "validations" do
      scenario "validation errors work as expected" do
        parent = create(:fund_activity, :gcrf, organisation: user.organisation)
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
        expect(page).to have_content t("form.label.activity.delivery_partner_identifier")

        # Don't provide an identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.delivery_partner_identifier.blank")

        fill_in "activity[delivery_partner_identifier]", with: identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.roda_identifier_fragment", level: "programme")

        # Provide an invalid identifier
        fill_in "activity[roda_identifier_fragment]", with: "!!!"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.roda_identifier_fragment.invalid_characters")

        fill_in "activity[roda_identifier_fragment]", with: identifier
        click_button t("form.button.activity.submit")
        expect(page).to have_content custom_capitalisation(t("form.legend.activity.purpose", level: "programme (level B)"))
        expect(page).to have_content t("form.hint.activity.title", level: "programme (level B)")

        # Don't provide a title and description
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("activerecord.errors.models.activity.attributes.title.blank")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.description.blank")

        fill_in "activity[title]", with: Faker::Lorem.word
        fill_in "activity[description]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.objectives", level: "programme (level B)")

        # Don't provide any objectives

        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.objectives.blank")

        fill_in "activity[objectives]", with: Faker::Lorem.paragraph
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector_category", level: "programme (level B)")

        # Don't provide a sector category
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector_category.blank")

        choose "Basic Education"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.sector", sector_category: "Basic Education", level: "programme (level B)")
        # Don't provide a sector
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sector.blank")

        choose "Primary education"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.programme_status", level: "programme (level B)")

        # Don't provide a programme status
        click_button t("form.button.activity.submit")
        expect(page).to have_content "can't be blank"

        choose("activity[programme_status]", option: "spend_in_progress")
        click_button t("form.button.activity.submit")

        if parent.roda_identifier_compound.include?("NF")
          expect(page).to have_content t("form.legend.activity.country_delivery_partners")

          # Don't provide a country delivery partner
          click_button t("form.button.activity.submit")
          expect(page).to have_content t("activerecord.errors.models.activity.attributes.country_delivery_partners.blank")

          fill_in "activity[country_delivery_partners][]", match: :first, with: "National Council for the State Funding Agencies (CONFAP)"
          click_button t("form.button.activity.submit")
        end
        expect(page).to have_content t("page_title.activity_form.show.dates", level: "programme (level B)")

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
        expect(page). to have_content t("form.label.activity.collaboration_type")

        # Collaboration_type has a pre-selected option
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.label.activity.flow")

        # Flow has a default and can't be set to blank so we skip
        select "ODA", from: "activity[flow]"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.sdgs_apply")

        # Choose option that SDGs apply, but do not select any SDGs
        choose "activity[sdgs_apply]", option: "true"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.sdg_1.blank")

        # Now select a primary SDG
        select "Quality Education", from: "activity[sdg_1]"
        click_button t("form.button.activity.submit")
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
        expect(page).to have_content t("form.legend.activity.gcrf_challenge_area")
        expect(page).to have_content t("form.hint.activity.gcrf_challenge_area")

        # Don't select a GCRF challenge area
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.gcrf_challenge_area.blank")

        # GCRF challenge area (GCRF)
        choose("activity[gcrf_challenge_area]", option: "1")
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.oda_eligibility")

        # oda_eligibility has the default value already selected
        click_button t("form.button.activity.submit")
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

    scenario "the activity has the appropriate funding organisation defaults" do
      fund = create(:activity, level: :fund, organisation: user.organisation)
      identifier = "a-programme-has-a-funding-organisation"

      visit activities_path
      click_on fund.title
      click_on t("tabs.activity.children")
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(delivery_partner_identifier: identifier, level: "programme", parent: fund)

      activity = Activity.find_by(delivery_partner_identifier: identifier)
      expect(activity.funding_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-13")
      expect(activity.funding_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      fund = create(:activity, level: :fund, organisation: user.organisation)
      identifier = "a-fund-has-an-accountable-organisation"

      visit activities_path
      click_on fund.title
      click_on t("tabs.activity.children")
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(delivery_partner_identifier: identifier, level: "programme", parent: fund)

      activity = Activity.find_by(delivery_partner_identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "the activity saves its identifier as read-only `transparency_identifier`" do
      fund = create(:activity, level: :fund, organisation: user.organisation)
      identifier = "a-programme"

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(roda_identifier_fragment: identifier, level: "programme", parent: fund)

      activity = Activity.find_by(roda_identifier_fragment: identifier)
      expect(activity.transparency_identifier).to eql("GB-GOV-13-#{fund.roda_identifier_fragment}-#{activity.roda_identifier_fragment}")
    end

    scenario "programme creation is tracked with public_activity" do
      fund = create(:activity, level: :fund, organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path
        click_on fund.title
        click_on t("tabs.activity.children")
        click_on(t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(delivery_partner_identifier: "my-unique-identifier", level: "programme", parent: fund)

        programme = Activity.find_by(delivery_partner_identifier: "my-unique-identifier")
        auditable_events = PublicActivity::Activity.where(trackable_id: programme.id)
        expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
        expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
        expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [programme.id]
      end
    end

    scenario "country_delivery_parters is included in Newton funded programmes" do
      newton_fund = create(:fund_activity, :newton, organisation: user.organisation)
      identifier = "newton-prog"
      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "programme", roda_identifier_fragment: identifier, parent: newton_fund)

      expect(page).to have_content t("action.programme.create.success")
      activity = Activity.find_by(roda_identifier_fragment: identifier)
      expect(activity.country_delivery_partners).to eql(["National Council for the State Funding Agencies (CONFAP)"])
    end

    scenario "non Newton funded programmes do not include 'country_delivery_partners'" do
      other_fund = create(:fund_activity, organisation: user.organisation)
      identifier = "other-prog"
      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "programme", roda_identifier_fragment: identifier, parent: other_fund)

      expect(page).to have_content t("action.programme.create.success")
      activity = Activity.find_by(roda_identifier_fragment: identifier)
      expect(activity.country_delivery_partners).to be_nil
    end

    scenario "a new programme requires specific fields when the programme is Newton-funded" do
      newton_fund = create(:fund_activity, :newton)
      _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)

      visit activities_path
      click_on(t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "programme", parent: newton_fund)
    end
  end
end
