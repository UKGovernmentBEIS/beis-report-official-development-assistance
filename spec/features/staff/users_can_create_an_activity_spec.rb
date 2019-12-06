RSpec.feature "Users can create an activity" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let!(:fund) { create(:fund, organisation: organisation, name: "My Space Fund") }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit fund_path(fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the hierarchy is a Fund" do
    scenario "successfully creating an activity with all optional information" do
      visit fund_path(fund)
      click_on I18n.t("page_content.fund.button.create_activity")

      expect(page).to have_content I18n.t("page_title.activity_form.show.identifier")
      fill_in "activity[identifier]", with: "A-Unique-Identifier"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.purpose")
      fill_in "activity[title]", with: "My Aid Activity"
      fill_in "activity[description]", with: Faker::Lorem.paragraph
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.sector")
      select "Education policy and administrative management", from: "activity[sector]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.status")
      select "Implementation", from: "activity[status]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.dates")
      fill_in "planned_start_date[day]", with: "1"
      fill_in "planned_start_date[month]", with: "1"
      fill_in "planned_start_date[year]", with: "2020"
      fill_in "planned_end_date[day]", with: "1"
      fill_in "planned_end_date[month]", with: "1"
      fill_in "planned_end_date[year]", with: "2021"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.country")
      select "Developing countries, unspecified", from: "activity[recipient_region]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.flow")
      select "ODA", from: "activity[flow]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.finance")
      select "Standard grant", from: "activity[finance]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")
      select "General budget support", from: "activity[aid_type]"
      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("page_title.activity_form.show.tied_status")
      select "Untied", from: "activity[tied_status]"

      click_button I18n.t("form.activity.submit")

      expect(page).to have_content I18n.t("form.activity.create.success")
      expect(page).to have_content "A-Unique-Identifier"
      expect(page).to have_content "Education policy and administrative management"
      expect(page).to have_content "My Aid Activity"
      expect(page).to have_content "Developing countries, unspecified"
      expect(page).to have_content "ODA"
      expect(page).to have_content "Standard grant"
      expect(page).to have_content "General budget support"
      expect(page).to have_content "Untied"
      expect(page).to have_content "2020-01-01"
      expect(page).to have_content "2021-01-01"
    end

    context "validations" do
      scenario "validation errors work as expected" do
        visit fund_path(fund)
        click_on I18n.t("page_content.fund.button.create_activity")
        click_button I18n.t("form.activity.submit")
        expect(page).not_to have_content I18n.t("form.activity.create.success")
        expect(page).to have_content "can't be blank"
      end
    end

    scenario "can go back to the previous page" do
      visit fund_path(fund)
      click_on I18n.t("page_content.fund.button.create_activity")

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(fund.id, organisation_id: organisation.id))
    end
  end
end
