RSpec.feature "Users can edit an activity" do
  include ActivityHelper

  before { authenticate!(user: user) }

  context "when the activity is a fund" do
    let(:user) { create(:beis_user) }

    context "when the activity only has an identifier (and is incomplete)" do
      it "shows edit link on the identifier, and add link on only the next step" do
        activity = create(:fund_activity, :at_purpose_step, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        # Click the first edit link that opens the form on step 1
        within(".identifier") do
          expect(page).to have_content(I18n.t("generic.link.edit"))
        end

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.add"))
        end

        within(".sector_category") do
          expect(page).to_not have_content(I18n.t("generic.link.add"))
        end
      end
    end

    context "when the activity is complete" do
      it "editing and saving a step returns the user to the activity page" do
        activity = create(:fund_activity, organisation: user.organisation)
        identifier = "AB-CDE-1234"
        visit organisation_activity_path(activity.organisation, activity)

        within(".identifier") do
          click_on(I18n.t("generic.link.edit"))
        end

        fill_in "activity[identifier]", with: identifier
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("form.fund.update.success")
        expect(page.current_path).to eq organisation_activity_path(activity.organisation, activity)
      end

      it "all edit links are available to take the user to the right step" do
        activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
      end

      it "tracks activity updates with public_activity" do
        activity = create(:fund_activity, organisation: user.organisation)
        identifier = "AB-CDE-1234"
        PublicActivity.with_tracking do
          visit organisation_activity_path(activity.organisation, activity)

          within(".identifier") do
            click_on(I18n.t("generic.link.edit"))
          end

          fill_in "activity[identifier]", with: identifier
          click_button I18n.t("form.activity.submit")

          # grab the most recently created auditable_event
          auditable_events = PublicActivity::Activity.where(trackable_id: activity.id).order("created_at ASC")
          expect(auditable_events.first.key).to eq "activity.update.identifier"
          expect(auditable_events.first.owner_id).to eq user.id
          expect(auditable_events.first.trackable_id).to eq activity.id
        end
      end
    end

    context "when the activity is incomplete" do
      it "editing and saving a step goes to the next step in the form" do
        activity = create(:fund_activity, :at_region_step, organisation: user.organisation)
        recipient_region = "Oceania, regional"

        visit organisation_activity_path(activity.organisation, activity)

        within(".recipient_region") do
          click_on(I18n.t("generic.link.edit"))
        end

        select recipient_region, from: "activity[recipient_region]"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_content I18n.t("page_title.activity_form.show.flow")
        expect(page).not_to have_content activity.title
      end
    end

    context "when a title attribute is present" do
      it "the call to action is 'Edit'" do
        activity = create(:fund_activity, organisation: user.organisation, wizard_status: :sector)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.edit"))
        end
      end
    end

    context "when an activity attribute is not present" do
      it "the call to action is 'Add'" do
        activity = create(:fund_activity, :at_purpose_step, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          expect(page).to have_content(I18n.t("generic.link.add"))
        end
      end
    end
  end

  context "when the activity is a programme" do
    context "when the user is a BEIS user" do
      let(:user) { create(:beis_user) }

      it "shows an update success message" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          click_on(I18n.t("generic.link.edit"))
        end

        click_button I18n.t("form.activity.submit")
        expect(page).to have_content(I18n.t("form.programme.update.success"))
      end
    end

    context "when the user is NOT a BEIS user" do
      let(:user) { create(:delivery_partner_user) }

      scenario "the user should not be shown edit/add actions" do
        activity = create(:programme_activity, :at_purpose_step, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).not_to have_content("Edit")
        expect(page).not_to have_content("Add")
      end
    end
  end

  context "when the activity is a project" do
    context "when the user is a delivery_partner_user" do
      let(:user) { create(:delivery_partner_user) }

      it "shows an update success message" do
        activity = create(:project_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        within(".title") do
          click_on(I18n.t("generic.link.edit"))
        end

        click_button I18n.t("form.activity.submit")
        expect(page).to have_content(I18n.t("form.project.update.success"))
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
      activity_step_path(activity, :sector_category)
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

  within(".geography") do
    click_on(I18n.t("generic.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :geography)
    )
  end
  click_on(I18n.t("generic.link.back"))

  within(".recipient_region") do
    click_on(I18n.t("generic.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :region)
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

  within(".aid_type") do
    click_on(I18n.t("generic.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :aid_type)
    )
  end
  click_on(I18n.t("generic.link.back"))
end
