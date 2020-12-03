RSpec.feature "Users can edit an activity" do
  include ActivityHelper

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    it "shows the Publish to Iati field" do
      activity = create(:third_party_project_activity, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.details")

      expect(page).to have_content(t("summary.label.activity.publish_to_iati.label"))
    end

    it "allows the user to redact the activity from Iati" do
      activity = create(:third_party_project_activity, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.details")

      within ".publish_to_iati" do
        click_on(t("default.link.edit"))
      end

      choose t("summary.label.activity.publish_to_iati.false")
      click_button t("form.button.activity.submit")

      click_on t("tabs.activity.details")
      within ".publish_to_iati" do
        expect(page).to have_content(t("summary.label.activity.publish_to_iati.false"))
      end
    end

    it "also redacts any child third-party projects when a project is redacted" do
      project_activity = create(:project_activity, organisation: user.organisation)
      third_party_project_activity = create(:third_party_project_activity, parent: project_activity, organisation: user.organisation)

      visit organisation_activity_path(project_activity.organisation, project_activity)
      click_on t("tabs.activity.details")

      within ".publish_to_iati" do
        click_on(t("default.link.edit"))
      end

      choose t("summary.label.activity.publish_to_iati.false")
      click_button t("form.button.activity.submit")

      click_on t("tabs.activity.details")

      within ".publish_to_iati" do
        expect(page).to have_content(t("summary.label.activity.publish_to_iati.false"))
      end

      visit organisation_activity_path(third_party_project_activity.organisation, third_party_project_activity)
      click_on t("tabs.activity.details")

      within ".publish_to_iati" do
        expect(page).to have_content(t("summary.label.activity.publish_to_iati.false"))
      end
    end

    context "before the activity has a level" do
      it "shows add link on the level step" do
        activity = create(:activity, :level_form_state, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".level") do
          expect(page).to have_content(t("default.link.add"))
        end

        within(".parent") do
          expect(page).not_to have_content(t("default.link.add"))
        end
      end
    end

    context "when the activity is a fund level activity" do
      it "does not show the parent field" do
        activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).not_to have_content(t("summary.label.activity.parent"))
      end

      it "does not show the Publish to Iati field" do
        activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end

      context "when a title attribute is present" do
        let(:user) { create(:beis_user) }
        it "the call to action is 'Edit'" do
          activity = create(:fund_activity, organisation: user.organisation, form_state: :sector)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".title") do
            expect(page).to have_content(t("default.link.edit"))
          end
        end
      end

      context "when an activity attribute is not present" do
        it "the call to action is 'Add'" do
          activity = create(:fund_activity, :at_purpose_step, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".title") do
            expect(page).to have_content(t("default.link.add"))
          end
        end
      end

      context "when the activity is complete" do
        it "editing and saving a step returns the user to the activity page details tab" do
          activity = create(:fund_activity, organisation: user.organisation)
          identifier = "AB-CDE-1234"
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".identifier") do
            click_on(t("default.link.edit"))
          end

          fill_in "activity[delivery_partner_identifier]", with: identifier
          click_button t("form.button.activity.submit")

          expect(page).to have_content t("action.fund.update.success")
          expect(page.current_path).to eq organisation_activity_details_path(activity.organisation, activity)
        end

        it "all edit links are available to take the user to the right step" do
          activity = create(:fund_activity, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
        end

        it "does not show an edit link for the transparency identifier" do
          activity = create(:fund_activity, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".transparency-identifier") do
            expect(page).to_not have_content t("default.link.edit")
          end
        end

        it "tracks activity updates with public_activity" do
          activity = create(:fund_activity, organisation: user.organisation)
          identifier = "AB-CDE-1234"
          PublicActivity.with_tracking do
            visit organisation_activity_details_path(activity.organisation, activity)

            within(".identifier") do
              click_on(t("default.link.edit"))
            end

            fill_in "activity[delivery_partner_identifier]", with: identifier
            click_button t("form.button.activity.submit")

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

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".recipient_region") do
            click_on(t("default.link.edit"))
          end
          choose "Region"
          click_button t("form.button.activity.submit")
          select recipient_region, from: "activity[recipient_region]"
          click_button t("form.button.activity.submit")

          expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
          expect(page).not_to have_content activity.title
        end

        context "when the activity only has an identifier" do
          it "shows edit link on the identifier, and add link on only the next step" do
            activity = create(:fund_activity, :at_purpose_step, organisation: user.organisation)

            visit organisation_activity_details_path(activity.organisation, activity)

            # Click the first edit link that opens the form on step 1
            within(".identifier") do
              expect(page).to have_content(t("default.link.edit"))
            end

            within(".title") do
              expect(page).to have_content(t("default.link.add"))
            end

            within(".sector") do
              expect(page).to_not have_content(t("default.link.add"))
            end
          end
        end
      end
    end

    context "when the activity is programme level activity" do
      it "shows an update success message" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".title") do
          click_on(t("default.link.edit"))
        end

        click_button t("form.button.activity.submit")
        expect(page).to have_content(t("action.programme.update.success"))
      end

      it "does not show the Publish to Iati field" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end

      context "when the activity was left at the parent step" do
        it "shows add link on the parent step" do
          activity = create(:programme_activity, :parent_form_state, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)
          within(".parent") do
            expect(page).to have_content(t("default.link.add"))
          end
          within(".identifier") do
            expect(page).not_to have_content(t("default.link.add"))
          end
        end
      end

      # Changing the level means the IATI identifier we construct changes
      # If this is changed after publishing to IATI the effect will be a branch
      # new IATI publiciation.
      context "when the activity has a level and a parent" do
        it "it cannot be edited" do
          activity = create(:programme_activity, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".level") do
            expect(page).not_to have_content(t("default.link.add"))
          end

          within(".parent") do
            expect(page).not_to have_content(t("default.link.add"))
          end
        end
      end
    end
  end

  context "when signed in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "and the activity is a programme" do
      scenario "the user should not be shown edit/add actions" do
        activity = create(:programme_activity, :at_purpose_step)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).not_to have_content("Edit")
        expect(page).not_to have_content("Add")
      end

      scenario "it does not show the Publish to Iati field" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end
    end

    context "when the activity is a project" do
      it "shows an update success message" do
        activity = create(:project_activity, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".title") do
          click_on(t("default.link.edit"))
        end

        click_button t("form.button.activity.submit")
        expect(page).to have_content(t("action.project.update.success"))
      end

      it "does not show the Publish to Iati field" do
        activity = create(:project_activity, organisation: user.organisation)

        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end

      context "when the project does not have a RODA identifier" do
        let(:fund) { create(:fund_activity, roda_identifier_fragment: "AAA") }
        let(:programme) { create(:programme_activity, parent: fund, roda_identifier_fragment: "BBB") }

        scenario "a RODA identifier can be added" do
          activity = create(:project_activity, organisation: user.organisation, parent: programme, roda_identifier_fragment: nil)
          _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".roda_identifier") { click_on(t("default.link.add")) }
          fill_in "activity[roda_identifier_fragment]", with: "CCC"
          click_button t("form.button.activity.submit")

          expect(page).to have_content(t("action.project.update.success"))
          expect(activity.reload.roda_identifier).to eq("AAA-BBB-CCC")
        end
      end

      context "when the project has a RODA identifier" do
        let(:activity) { create(:project_activity, organisation: user.organisation, roda_identifier_fragment: "A-RODA-ID") }

        scenario "the RODA identifier cannot be edited" do
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".roda_identifier") do
            expect(page).not_to have_content(t("default.link.add"))
            expect(page).not_to have_content(t("default.link.edit"))
          end
        end
      end

      context "when the project's parent does not have a RODA identifier" do
        let(:activity) { create(:project_activity, organisation: user.organisation, roda_identifier_fragment: nil) }

        before do
          activity.parent.update!(roda_identifier_fragment: nil)
        end

        scenario "a RODA identifier cannot be added" do
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".roda_identifier") do
            expect(page).not_to have_content(t("default.link.add"))
            expect(page).not_to have_content(t("default.link.edit"))
          end
        end
      end

      context "when the project is Newton-funded" do
        let(:activity) { create(:project_activity, organisation: user.organisation, parent: create(:programme_activity, parent: create(:fund_activity, :newton))) }

        it "shows a link to edit the UK DP named contact" do
          # Report needs to exist so the activity is editable
          _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".uk_dp_named_contact") do
            click_on(t("default.link.edit"))
            expect(page).to have_current_path(
              activity_step_path(activity, :uk_dp_named_contact)
            )
          end
        end
      end
    end

    context "when the activity is a third-party project" do
      it "shows an update success message" do
        activity = create(:third_party_project_activity, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".title") do
          click_on(t("default.link.edit"))
        end

        click_button t("form.button.activity.submit")
        expect(page).to have_content(t("action.third_party_project.update.success"))
      end
    end

    context "when editing an invalid activity that is already saved" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }

      it "saves the value and shows an update success message" do
        activity.update_columns(title: nil, programme_status: "Replace me")
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".programme_status") do
          click_on(t("default.link.edit"))
        end
        choose "Spend in progress"
        click_button t("form.button.activity.submit")

        expect(page).to have_content(t("action.project.update.success"))
        expect(activity.reload.programme_status).to eql("07")
      end
    end
  end
end

def assert_all_edit_links_go_to_the_correct_form_step(activity:)
  within(".identifier") do
    click_on t("default.link.edit")
    expect(page).to have_current_path(
      activity_step_path(activity, :identifier)
    )
  end
  click_on t("default.link.back")
  click_on t("tabs.activity.details")

  within(".sector") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :sector_category)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".title") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :purpose)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".description") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :purpose)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  if activity.call_present?
    within(".total_applications") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :total_applications_and_awards)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")

    within(".total_awards") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :total_applications_and_awards)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end

  unless activity.fund?
    within(".programme_status") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :programme_status)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end

  within(".planned_start_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".planned_end_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".actual_start_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".actual_end_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".recipient_region") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :geography)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".intended_beneficiaries") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :intended_beneficiaries)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".gdi") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :gdi)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  if activity.is_gcrf_funded?
    within(".gcrf_challenge_area") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :gcrf_challenge_area)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end

  unless activity.fund?
    within(".collaboration_type") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :collaboration_type)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end

  within(".flow") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :flow)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".aid_type") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :aid_type)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".fstc_applies") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :fstc_applies)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".covid19_related") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :covid19_related)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  within(".oda_eligibility") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :oda_eligibility)
    )
  end
  click_on(t("default.link.back"))
  click_on t("tabs.activity.details")

  if activity.is_project?
    within(".oda_eligibility_lead") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :oda_eligibility_lead)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end

  if activity.is_project? && activity.is_newton_funded?
    within(".uk_dp_named_contact") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :uk_dp_named_contact)
      )
    end
    click_on(t("default.link.back"))
    click_on t("tabs.activity.details")
  end
end
