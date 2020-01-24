RSpec.feature "Fund managers can create a fund" do
  let!(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit new_organisation_fund_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: create(:fund_manager, organisations: [])) }

    scenario "successfully create a fund" do
      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "the fund form has some defaults" do
      fund = create(:fund, organisation: organisation)
      activity_presenter = ActivityPresenter.new(fund)
      visit organisation_path(organisation)

      click_on I18n.t("page_content.organisation.button.create_fund")

      visit fund_step_path(fund, :country)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.recipient_region

      visit fund_step_path(fund, :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.flow

      visit fund_step_path(fund, :tied_status)
      expect(page.find("option[@selected = 'selected']").text).to eq activity_presenter.tied_status
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit organisation_path(organisation)
        click_on I18n.t("page_content.organisation.button.create_fund")

        # Don't provide an identifier
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content "can't be blank"

        fill_in "fund[identifier]", with: "foo"
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")

        # Don't provide a title and description
        click_button I18n.t("form.fund.submit")

        expect(find_field("Title").value).to eq "Untitled fund"
        expect(page).to have_content "Description can't be blank"

        fill_in "fund[title]", with: Faker::Lorem.word
        fill_in "fund[description]", with: Faker::Lorem.paragraph
        click_button I18n.t("form.fund.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.sector")

        # Don't provide a sector
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content "Sector can't be blank"

        select "Education policy and administrative management", from: "fund[sector]"
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.status")

        # Don't provide a status
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content "Status can't be blank"

        select "Implementation", from: "fund[status]"
        click_button I18n.t("form.fund.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.dates")

        # Dates are not mandatory so we can move through this step
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.country")

        # Region has a default and can't be set to blank so we skip
        select "Developing countries, unspecified", from: "fund[recipient_region]"
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.flow")

        # Flow has a default and can't be set to blank so we skip
        select "ODA", from: "fund[flow]"
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.finance")

        # Don't select a finance
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content "Finance can't be blank"

        select "Standard grant", from: "fund[finance]"
        click_button I18n.t("form.fund.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")

        # Don't select an aid type
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content "Aid type can't be blank"

        select "General budget support", from: "fund[aid_type]"
        click_button I18n.t("form.fund.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")

        # Tied status has a default and can't be set to blank so we skip
        select "Untied", from: "fund[tied_status]"
        click_button I18n.t("form.fund.submit")
        expect(page).to have_content Fund.last.title
      end
    end

    scenario "can go back to the previous page" do
      visit new_organisation_fund_path(organisation_id: organisation.id)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation.id))
    end

    context "when the title isn't provided" do
      scenario "shows the user a default fund title rather than a link with no title" do
        visit dashboard_path
        click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
        click_on(organisation.name)
        click_on(I18n.t("page_content.organisation.button.create_fund"))
        click_on(I18n.t("generic.link.back")) # Back to the fund show page
        click_on(I18n.t("generic.link.back")) # Back to the organisation page

        expect(page).to have_content("Untitled fund")
      end
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisations: [organisation])) }

    scenario "hides the 'Create fund' button" do
      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_on(organisation.name)

      expect(page).to have_no_content(I18n.t("page_content.organisation.button.create_fund"))
    end

    scenario "shows the 'unauthorised' error message to the user" do
      visit new_organisation_fund_path(organisation)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
