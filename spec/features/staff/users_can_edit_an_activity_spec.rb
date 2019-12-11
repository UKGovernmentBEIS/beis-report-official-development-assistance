RSpec.feature "Users can edit an activity" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation, name: "UKSA") }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the activity belongs to a fund" do
    it "clicking edit starts the ActivityForm journey from that step" do
      fund = create(:fund, organisation: organisation)
      create(:activity, hierarchy: fund)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(fund.name)

      # Click the first edit link that opens the form on step 1
      within(".identifier") do
        click_on(I18n.t("generic.link.edit"))
      end

      # This helper fills in the form from step 1
      fill_in_activity_form
    end

    it "all edit links are available to take the user to the right step" do
      fund = create(:fund, organisation: organisation)
      activity = create(:activity, hierarchy: fund)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(fund.name)

      assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
    end
  end

  def assert_all_edit_links_go_to_the_correct_form_step(activity:)
    within(".identifier") do
      click_on I18n.t("generic.link.edit")
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/identifier"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".sector") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/sector"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".title") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/purpose"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".description") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/purpose"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".status") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/status"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".planned_start_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/dates"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".planned_end_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/dates"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".actual_start_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/dates"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".actual_end_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/dates"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".recipient_region") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/country"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".flow") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/flow"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".finance") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/finance"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".aid_type") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/aid_type"
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".tied_status") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        url_for([activity.hierarchy, activity]) + "/steps/tied_status"
      )
    end
    click_on(I18n.t("generic.link.back"))
  end
end
