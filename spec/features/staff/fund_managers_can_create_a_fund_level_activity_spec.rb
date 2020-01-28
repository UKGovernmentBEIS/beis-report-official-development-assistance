RSpec.feature "Fund managers can create a fund level activity" do
  let!(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit activity_step_path(double(Activity, id: "123"), :identifier)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: create(:fund_manager, organisations: [])) }

    scenario "successfully create a activity" do
      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "the activity form has some defaults" do
      activity = create(:activity, organisation: organisation)
      activity_presenter = ActivityPresenter.new(activity)
      visit organisation_path(organisation)

      click_on I18n.t("page_content.organisation.button.create_fund")

      visit activity_step_path(activity, :country)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region

      visit activity_step_path(activity, :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.flow

      visit activity_step_path(activity, :tied_status)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.tied_status
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit organisation_path(organisation)
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
        expect(page).to have_content I18n.t("page_title.activity_form.show.country")

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

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisations: [organisation])) }

    scenario "hides the 'Create activity' button" do
      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_on(organisation.name)

      expect(page).to have_no_content(I18n.t("page_content.organisation.button.create_fund"))
    end

    scenario "shows the 'unauthorised' error message to the user" do
      another_organisations_activity = create(:activity)

      visit activity_step_path(another_organisations_activity, :identifier)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
