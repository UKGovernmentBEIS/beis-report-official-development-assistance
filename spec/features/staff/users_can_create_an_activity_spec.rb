RSpec.feature "Users can create an activity" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let!(:fund) { create(:fund, organisation: organisation, name: "My Space Fund") }
  let(:user) { create(:administrator, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the hierarchy is a Fund" do
    scenario "successfully creating an activity with all optional information" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")

      fill_in_activity_form
    end

    scenario "the activity form has some defaults" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")
      activity = Activity.last

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :country)
      expect(page.find("option[@selected = 'selected']").text).to eq("Developing countries, unspecified")

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :flow)
      expect(page.find("option[@selected = 'selected']").text).to eq("ODA")

      visit fund_activity_steps_path(fund_id: fund, activity_id: activity, id: :tied_status)
      expect(page.find("option[@selected = 'selected']").text).to eq("Untied")
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit organisation_fund_path(organisation, fund)
        click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")

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
        expect(page).to have_content fund.name
      end
    end

    scenario "can go back to the previous page" do
      visit organisation_fund_path(organisation, fund)
      click_on I18n.t("page_content.fund.button.create_activity", activity: "fund")

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(fund.id, organisation_id: organisation.id))
    end
  end
end
