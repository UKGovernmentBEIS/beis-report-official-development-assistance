RSpec.feature "Fund managers can edit an activity" do
  include ActivityHelper

  let(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisations: [organisation])) }

    scenario "clicking edit starts the ActivityForm journey from that step" do
      activity = create(:activity, organisation: organisation)

      visit organisation_activity_path(activity.organisation, activity)

      # Click the first edit link that opens the form on step 1
      within(".identifier") do
        click_on(I18n.t("generic.link.edit"))
      end

      # This helper fills in the form from step 1
      fill_in_activity_form

      # TODO: On Edit we shouldn't show a message that says "successfully created"
      expect(page).to have_content I18n.t("form.activity.create.success")
    end

    context "when the activity only has an identifier (and is incomplete)" do
      it "shows edit link on the identifier, and add link on only the next step" do
        activity = create(:activity, :at_purpose_step, organisation: organisation)

        visit organisation_activity_path(activity.organisation, activity)

        within(".identifier") do
          expect(page).to have_content(I18n.t("generic.link.edit"))
        end

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.add"))
        end

        within(".sector") do
          expect(page).to_not have_content(I18n.t("generic.link.add"))
        end
      end
    end

    context "when the activity is complete" do
      it "all edit links are available to take the user to the right step" do
        activity = create(:activity, organisation: organisation)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
        click_on(organisation.name)
        click_on(activity.title)

        assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
      end
    end

    context "when a title attribute is present" do
      it "the call to action is 'Edit'" do
        activity = create(:activity, organisation: organisation, wizard_status: :sector)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.edit"))
        end
      end
    end

    context "when an activity attribute is not present" do
      it "the call to action is 'Add'" do
        activity = create(:activity, :at_purpose_step, organisation: organisation)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.add"))
        end
      end
    end
  end

  def assert_all_edit_links_go_to_the_correct_form_step(activity:)
    within(".identifier") do
      click_on I18n.t("generic.link.edit")
      expect(page).to have_current_path(
        activity_step_path(activity, :identifier)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".sector") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :sector)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".title") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :purpose)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".description") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :purpose)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".status") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :status)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".planned_start_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :dates)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".planned_end_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :dates)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".actual_start_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :dates)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".actual_end_date") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :dates)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".recipient_region") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :country)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".flow") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :flow)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".finance") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :finance)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".aid_type") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :aid_type)
      )
    end
    click_on(I18n.t("generic.link.back"))

    within(".tied_status") do
      click_on(I18n.t("generic.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :tied_status)
      )
    end
    click_on(I18n.t("generic.link.back"))
  end
end
