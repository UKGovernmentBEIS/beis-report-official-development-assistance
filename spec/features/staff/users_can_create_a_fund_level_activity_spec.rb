RSpec.feature "Users can create a fund level activity" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
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

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "the activity form has some defaults" do
      activity = create(:fund_activity, organisation: user.organisation)
      activity_presenter = ActivityPresenter.new(activity)
      visit organisation_path(user.organisation)

      click_on I18n.t("page_content.organisation.button.create_fund")

      visit activity_step_path(activity, :country)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region

      visit activity_step_path(activity, :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.flow

      visit activity_step_path(activity, :tied_status)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.tied_status
    end

    scenario "the activity has the appropriate funding organisation defaults" do
      identifier = "a-fund-has-a-funding-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.funding_organisation_name).to eq("HM Treasury")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-2")
      expect(activity.funding_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      identifier = "a-fund-has-an-accountable-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate extending organisation defaults" do
      identifier = "a-fund-has-an-extending-organisation"

      visit organisation_path(user.organisation)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form(identifier: identifier)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.extending_organisation).to eql(user.organisation)
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
        expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")

        # Don't provide a title and description
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content "Title can't be blank"
        expect(page).to have_content "Description can't be blank"

        fill_in "activity[title]", with: Faker::Lorem.word
        fill_in "activity[description]", with: Faker::Lorem.paragraph
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.sector")

        # Don't provide a sector
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Sector can't be blank"

        select "Education policy and administrative management", from: "activity[sector]"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.status")

        # Don't provide a status
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Status can't be blank"

        select "Implementation", from: "activity[status]"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.dates")

        # Dates are not mandatory so we can move through this step
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.region")

        # Region has a default and can't be set to blank so we skip
        select "Developing countries, unspecified", from: "activity[recipient_region]"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.flow")

        # Flow has a default and can't be set to blank so we skip
        select "ODA", from: "activity[flow]"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.finance")

        # Don't select a finance
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Finance can't be blank"

        select "Standard grant", from: "activity[finance]"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")

        # Don't select an aid type
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content "Aid type can't be blank"

        select "General budget support", from: "activity[aid_type]"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")

        # Tied status has a default and can't be set to blank so we skip
        select "Untied", from: "activity[tied_status]"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content Activity.last.title
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
