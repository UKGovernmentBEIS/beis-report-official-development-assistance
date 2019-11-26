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
      visit new_fund_activity_path(fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the hierarchy is a Fund" do
    scenario "successfully creating a minimal activity" do
      visit new_fund_activity_path(fund)

      expect(page).to have_content(I18n.t("page_title.activity.new"))
      fill_in "activity[identifier]", with: "A-Unique-Identifier"
      click_button I18n.t("form.organisation.submit")
      expect(page).to have_content I18n.t("form.activity.create.success")
    end

    scenario "successfully creating an activity with all optional information" do
      visit new_fund_activity_path(fund)

      fill_in "activity[identifier]", with: "A-Unique-Identifier"
      select "AidData", from: "activity[sector]"
      fill_in "activity[title]", with: "My Aid Activity"
      fill_in "activity[description]", with: Faker::Lorem.paragraph
      select "Implementation", from: "activity[status]"
      select "Developing countries, unspecified", from: "activity[recipient_region]"
      select "ODA", from: "activity[flow]"
      select "Standard grant", from: "activity[finance]"
      select "General budget support", from: "activity[aid_type]"
      select "Untied", from: "activity[tied_status]"
      fill_in "planned_start_date[day]", with: "1"
      fill_in "planned_start_date[month]", with: "1"
      fill_in "planned_start_date[year]", with: "2020"
      fill_in "planned_end_date[day]", with: "1"
      fill_in "planned_end_date[month]", with: "1"
      fill_in "planned_end_date[year]", with: "2021"
      click_button I18n.t("form.organisation.submit")

      expect(page).to have_content I18n.t("form.activity.create.success")
      expect(page).to have_content "A-Unique-Identifier"
      expect(page).to have_content "AidData"
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
        visit new_fund_activity_path(fund)

        click_button I18n.t("form.organisation.submit")
        expect(page).not_to have_content I18n.t("form.activity.create.success")
        expect(page).to have_content "can't be blank"
      end

      scenario "an activity cannot be created without a fund" do
        expect { visit "/activity/new" }.to raise_error(ActionController::RoutingError)
      end
    end

    scenario "can go back to the previous page" do
      visit new_fund_activity_path(fund)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(fund.id, organisation_id: organisation.id))
    end
  end
end
