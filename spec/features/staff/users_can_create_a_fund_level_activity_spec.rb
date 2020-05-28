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
      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(level: "fund")

      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "the activity form has some defaults" do
      activity = create(:fund_activity, organisation: user.organisation)
      activity_presenter = ActivityPresenter.new(activity)
      visit organisation_path(user.organisation)

      click_on I18n.t("page_content.organisation.button.create_fund")

      visit activity_step_path(activity, :region)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region

      visit activity_step_path(activity, :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.flow
    end

    scenario "the activity has the appropriate funding organisation defaults" do
      identifier = "a-fund-has-a-funding-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.funding_organisation_name).to eq("HM Treasury")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-2")
      expect(activity.funding_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      identifier = "a-fund-has-an-accountable-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate extending organisation defaults" do
      identifier = "a-fund-has-an-extending-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier, level: "fund")

      activity = Activity.find_by(identifier: identifier)
      expect(activity.extending_organisation).to eql(user.organisation)
    end

    context "when there is an existing activity with a nil identifier" do
      scenario "successfully create a activity" do
        visit organisation_path(user.organisation)
        click_on(I18n.t("page_content.organisation.button.create_fund"))

        visit organisation_path(user.organisation)
        click_on(I18n.t("page_content.organisation.button.create_fund"))

        fill_in_activity_form(level: "fund")

        expect(page).to have_content I18n.t("form.fund.create.success")
      end
    end

    context "when there is an existing activity with the same identifier" do
      scenario "cannot use the duplicate identifier" do
        identifier = "A-non-unique-identifier"
        create(:activity, identifier: identifier)
        visit organisation_path(user.organisation)
        click_on(I18n.t("page_content.organisation.button.create_fund"))

        fill_in "activity[identifier]", with: identifier
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content "Your unique identifier has already been taken"
      end
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit organisation_path(user.organisation)
        click_on I18n.t("page_content.organisation.button.create_fund")

        # Don't provide an identifier
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "can't be blank"

        fill_in "activity[identifier]", with: "foo"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.purpose_level", level: "fund")

        # Don't provide a title and description
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content "Title can't be blank"
        expect(page).to have_content "Description can't be blank"

        fill_in "activity[title]", with: Faker::Lorem.word
        fill_in "activity[description]", with: Faker::Lorem.paragraph
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.sector_category", level: "fund")

        # Don't provide a sector category
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "can't be blank"

        choose "Basic Education"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.sector", sector_category: "Basic Education", level: "fund")

        # Don't provide a sector
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "can't be blank"

        choose "Primary education"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("activerecord.attributes.activity.status")

        # Don't provide a status
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Status can't be blank"

        choose("activity[status]", option: "2")
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.dates")

        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Planned start date can't be blank"
        expect(page).to have_content "Planned end date can't be blank"

        # Dates cannot contain only a zero
        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 0
        fill_in "activity[planned_start_date(1i)]", with: 2010
        fill_in "activity[planned_end_date(3i)]", with: 0
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2010
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Planned start date can't be blank"
        expect(page).to have_content "Planned end date can't be blank"

        fill_in "activity[planned_start_date(3i)]", with: 1
        fill_in "activity[planned_start_date(2i)]", with: 12
        fill_in "activity[planned_start_date(1i)]", with: 2010
        fill_in "activity[planned_end_date(3i)]", with: 1
        fill_in "activity[planned_end_date(2i)]", with: 12
        fill_in "activity[planned_end_date(1i)]", with: 2010
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.geography")

        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "can't be blank"

        choose "Region"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.region")

        # region has the default value already selected
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("activerecord.attributes.activity.flow")

        # Flow has a default and can't be set to blank so we skip
        select "ODA", from: "activity[flow]"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")

        # Don't select an aid type
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Aid type can't be blank"

        choose("activity[aid_type]", option: "A01")
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content Activity.last.title
      end
    end

    scenario "fund creation is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit organisation_path(user.organisation)
        click_on(I18n.t("page_content.organisation.button.create_fund"))

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
      expect(page).not_to have_button(I18n.t("page_content.organisation.button.create_fund"))
    end
  end
end
