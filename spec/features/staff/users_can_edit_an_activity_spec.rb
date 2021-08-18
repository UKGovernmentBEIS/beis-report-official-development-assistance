RSpec.feature "Users can edit an activity" do
  include ActivityHelper
  include CodelistHelper

  def go_back(activity)
    within ".govuk-breadcrumbs" do
      click_link href: organisation_activity_path(activity.organisation, activity, tab: "details")
    end
  end

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    it "shows the Publish to Iati field" do
      activity = create(:third_party_project_activity)

      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.details")

      expect(page).to have_content(t("summary.label.activity.publish_to_iati.label"))
    end

    it "allows the user to redact the activity from Iati" do
      activity = create(:third_party_project_activity)

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
      project_activity = create(:project_activity)
      third_party_project_activity = create(:third_party_project_activity, parent: project_activity)

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

    context "when the activity is a fund level activity" do
      it "does not show the parent field" do
        activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).not_to have_content(t("summary.label.activity.parent"))
      end

      it "does not show the Publish to Iati field" do
        activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

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
          updated_description = "Some new text for the description field."
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".description") do
            click_on(t("default.link.edit"))
          end

          fill_in "activity[description]", with: updated_description
          click_button t("form.button.activity.submit")

          expect(page).to have_content t("action.fund.update.success")
          expect(page.current_path).to eq organisation_activity_details_path(activity.organisation, activity)

          expect_change_to_be_recorded_as_historical_event(
            field: "description",
            previous_value: activity.description,
            new_value: updated_description,
            activity: activity,
            report: nil # no report in this scenario. Realistic or failure in setup?
          )
        end

        it "all edit links are available to take the user to the right step" do
          activity = create(:programme_activity, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
        end

        it "does not show an edit link for collaboration type if it can be inferred from the aid type" do
          activity = create(:programme_activity, organisation: user.organisation, aid_type: "B02", fstc_applies: true)

          visit organisation_activity_details_path(activity.organisation, activity)

          assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
        end

        it "does not show an edit link for FSTC applies if it can be inferred from the aid type" do
          activity = create(:programme_activity, organisation: user.organisation, aid_type: "D02", fstc_applies: true)

          visit organisation_activity_details_path(activity.organisation, activity)

          assert_all_edit_links_go_to_the_correct_form_step(activity: activity)
        end

        it "does not show an edit link for the transparency identifier" do
          activity = create(:programme_activity, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".transparency-identifier") do
            expect(page).to_not have_content t("default.link.edit")
          end
        end
      end

      context "when the activity is incomplete" do
        it "editing and saving a step goes to the next step in the form" do
          activity = create(:fund_activity, :at_collaboration_type_step, organisation: user.organisation)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".description") do
            click_on(t("default.link.edit"))
          end
          click_button t("form.button.activity.submit")

          within("#main-content") do
            expect(page).to have_content t("form.legend.activity.sector_category", level: "fund (level A)")
            expect(page).not_to have_content activity.title
          end
        end

        context "when the activity only has an identifier" do
          it "only shows the add link on the next step" do
            activity = create(:fund_activity, :at_purpose_step, organisation: user.organisation)

            visit organisation_activity_details_path(activity.organisation, activity)

            within(".identifier") do
              expect(page).not_to have_content(t("default.link.edit"))
            end

            within(".title") do
              expect(page).to have_content(t("default.link.add"))
            end

            within(".sector") do
              expect(page).not_to have_content(t("default.link.add"))
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

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end

      it "does not show the Channel of delivery code field" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.channel_of_delivery_code"))
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

        expect(page).not_to have_link(t("default.link.edit"))
        expect(page).not_to have_link(t("default.link.add"))
      end

      scenario "it does not show the Publish to Iati field" do
        activity = create(:programme_activity)

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end
    end

    context "when the activity is a project" do
      it "does not show edit/add actions if there is no report" do
        activity = create(:project_activity, organisation: user.organisation)

        visit organisation_activity_details_path(activity.organisation, activity)

        within ".activity-details" do
          expect(page).not_to have_link(t("default.link.edit"))
          expect(page).not_to have_link(t("default.link.add"))
        end
      end

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

        visit organisation_activity_details_path(activity.organisation, activity)

        expect(page).to_not have_content(t("summary.label.activity.publish_to_iati.label"))
      end

      scenario "the delivery partner identifier cannot be changed" do
        activity = create(:project_activity, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".identifier") do
          expect(page).not_to have_content(t("default.link.edit"))
        end

        # not even by visiting the URL directly
        visit activity_step_path(activity, :identifier)
        expect(page).not_to have_content("Enter your unique identifier")
      end

      context "when the project does not have a delivery partner identifier" do
        scenario "the delivery partner identifier can be added" do
          activity = create(:project_activity, :at_identifier_step, organisation: user.organisation)
          _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

          visit organisation_activity_details_path(activity.organisation, activity)

          within(".identifier") do
            expect(page).to have_content(t("default.link.add"))
          end
        end
      end

      context "when the project has a RODA identifier" do
        let(:activity) { create(:project_activity, organisation: user.organisation, roda_identifier: "A-RODA-ID") }

        scenario "the RODA identifier cannot be edited" do
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".roda_identifier") do
            expect(page).not_to have_content(t("default.link.add"))
            expect(page).not_to have_content(t("default.link.edit"))
          end
        end
      end

      context "when the project's parent does not have a RODA identifier" do
        let(:activity) { create(:project_activity, organisation: user.organisation, roda_identifier: nil) }

        before do
          activity.parent.update!(roda_identifier: nil)
        end

        scenario "a RODA identifier cannot be added" do
          visit organisation_activity_details_path(activity.organisation, activity)

          within(".roda_identifier") do
            expect(page).not_to have_content(t("default.link.add"))
            expect(page).not_to have_content(t("default.link.edit"))
          end
        end
      end

      it "shows a link to edit the UK DP named contact" do
        activity = create(:project_activity, organisation: user.organisation)
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

      it "shows an error message when the user enters an invalid date" do
        activity = create(:project_activity, organisation: user.organisation, planned_start_date: Date.parse("2020-01-01"), actual_start_date: nil)
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".planned_start_date") do
          click_on(t("default.link.edit"))
        end

        fill_in "activity[planned_start_date(2i)]", with: "15"

        click_button t("form.button.activity.submit")
        expect(page).to have_content t("activerecord.errors.models.activity.attributes.planned_start_date.invalid")
      end

      it "the policy markers can be added" do
        activity = create(:project_activity, organisation: user.organisation)
        # Report needs to exist so the activity is editable
        report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".policy_marker_gender") do
          click_on(t("default.link.edit"))
          expect(page.current_url).to match(activity_step_path(activity, :policy_markers, anchor: "gender"))
        end

        choose "activity-policy-marker-gender-significant-objective-field"
        click_button t("form.button.activity.submit")

        expect(page).to have_css(".policy_marker_gender", text: "Significant objective")

        expect_change_to_be_recorded_as_historical_event(
          field: "policy_marker_gender",
          previous_value: "not_assessed",
          new_value: "significant_objective",
          activity: activity,
          report: report
        )
      end

      it "the existing policy marker selections are shown and preserved on edit" do
        activity = create(:project_activity, organisation: user.organisation, policy_marker_desertification: "significant_objective")
        # Report needs to exist so the activity is editable
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit activity_step_path(activity, :policy_markers)

        expect(page.find(:css, "#activity-policy-marker-desertification-significant-objective-field")).to be_checked

        click_button t("form.button.activity.submit")

        expect(page).to have_css(".policy_marker_desertification", text: "Significant objective")
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
        activity.update_columns(title: nil, collaboration_type: "Replace me")
        _report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)

        visit organisation_activity_details_path(activity.organisation, activity)

        within(".collaboration_type") do
          click_on(t("default.link.edit"))
        end
        choose "Bilateral"
        click_button t("form.button.activity.submit")

        expect(page).to have_content(t("action.project.update.success"))
        expect(activity.reload.collaboration_type).to eql("1")
      end
    end
  end
end

def assert_all_edit_links_go_to_the_correct_form_step(activity:)
  if activity.delivery_partner_identifier.blank?
    within(".identifier") do
      click_on t("default.link.edit")
      expect(page).to have_current_path(
        activity_step_path(activity, :identifier)
      )
    end

    go_back(activity)
  else
    within(".identifier") do
      expect(page).to_not have_link(t("default.link.edit"))
    end
  end

  within(".sector") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :sector_category)
    )
  end

  go_back(activity)

  within(".title") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :purpose)
    )
  end

  go_back(activity)

  within(".description") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :purpose)
    )
  end

  go_back(activity)

  if activity.call_present?
    within(".total_applications") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :total_applications_and_awards)
      )
    end

    go_back(activity)

    within(".total_awards") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :total_applications_and_awards)
      )
    end

    go_back(activity)
  end

  unless activity.fund?
    within(".programme_status") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :programme_status)
      )
    end

    go_back(activity)
  end

  within(".planned_start_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end

  go_back(activity)

  within(".planned_end_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end

  go_back(activity)

  within(".actual_start_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end

  go_back(activity)

  within(".actual_end_date") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :dates)
    )
  end

  go_back(activity)

  within(".benefitting_countries") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :benefitting_countries)
    )
  end

  go_back(activity)

  within(".gdi") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :gdi)
    )
  end

  go_back(activity)

  if activity.is_gcrf_funded?
    within(".gcrf_strategic_area") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :gcrf_strategic_area)
      )
    end

    go_back(activity)
  end

  if activity.is_gcrf_funded?
    within(".gcrf_challenge_area") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :gcrf_challenge_area)
      )
    end

    go_back(activity)
  end

  within(".aid_type") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :aid_type)
    )
  end

  go_back(activity)

  unless activity.fund?
    if Activity::Inference.service.editable?(activity, :collaboration_type)
      within(".collaboration_type") do
        click_on(t("default.link.edit"))
        expect(page).to have_current_path(
          activity_step_path(activity, :collaboration_type)
        )
      end

      go_back(activity)
    else
      within(".collaboration_type") do
        expect(page).to_not have_link(t("default.link.edit"))
      end
    end
  end

  if Activity::Inference.service.editable?(activity, :fstc_applies)
    within(".fstc_applies") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :fstc_applies)
      )
    end

    go_back(activity)
  else
    within(".fstc_applies") do
      expect(page).to_not have_link(t("default.link.edit"))
    end
  end

  within(".covid19_related") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :covid19_related)
    )
  end

  go_back(activity)

  if activity.is_newton_funded?
    within(".fund_pillar") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :fund_pillar)
      )
    end

    go_back(activity)
  end

  if activity.is_project?
    within(".channel_of_delivery_code") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :channel_of_delivery_code)
      )
    end

    go_back(activity)
  end

  within(".oda_eligibility") do
    click_on(t("default.link.edit"))
    expect(page).to have_current_path(
      activity_step_path(activity, :oda_eligibility)
    )
  end

  go_back(activity)

  if activity.is_project?
    within(".oda_eligibility_lead") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :oda_eligibility_lead)
      )
    end

    go_back(activity)
  end

  if activity.is_project?
    within(".uk_dp_named_contact") do
      click_on(t("default.link.edit"))
      expect(page).to have_current_path(
        activity_step_path(activity, :uk_dp_named_contact)
      )
    end

    go_back(activity)
  end
end

def expect_change_to_be_recorded_as_historical_event(
  field:,
  previous_value:,
  new_value:,
  activity:,
  report:
)
  historical_event = HistoricalEvent.last
  aggregate_failures do
    expect(historical_event.value_changed).to eq(field)
    expect(historical_event.previous_value).to eq(previous_value)
    expect(historical_event.new_value).to eq(new_value)
    expect(historical_event.activity).to eq(activity)
    expect(historical_event.report).to eq(report)
  end
end
