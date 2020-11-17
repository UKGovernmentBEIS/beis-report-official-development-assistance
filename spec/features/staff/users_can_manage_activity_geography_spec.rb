RSpec.feature "Users can provide the geography for an activity" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }
    let(:activity) { create(:activity, :at_geography_step, organisation: user.organisation) }

    scenario "they are asked to choose the geography" do
      visit activity_step_path(activity, :geography)
      expect(page).to have_content t("form.legend.activity.geography")
      expect(page).to have_button t("form.button.activity.submit")
    end

    context "when they choose country geography" do
      scenario "they skip the region step and go straight to the country step" do
        visit activity_step_path(activity, :geography)
        choose "Country"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.label.activity.recipient_country")
        expect(page).to have_current_path(activity_step_path(activity, :country))

        select "Uganda"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
        expect(page).to have_current_path(activity_step_path(activity, :requires_additional_benefitting_countries))
      end

      scenario "the region gets set in the background according to the selected country" do
        visit activity_step_path(activity, :geography)
        choose "Country"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.label.activity.recipient_country")
        expect(page).to have_current_path(activity_step_path(activity, :country))

        select "Uganda"
        click_button t("form.button.activity.submit")

        expect(activity.reload.recipient_region).to eq("1027") # Eastern Africa
      end
    end

    context "when they choose region geography" do
      scenario "they go to the region step and skip the country step" do
        visit activity_step_path(activity, :geography)
        choose "Region"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.label.activity.recipient_region")

        select "Developing countries, unspecified", from: "activity[recipient_region]"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
        expect(page).to have_current_path(activity_step_path(activity, :requires_additional_benefitting_countries))
      end
    end

    context "with a completed activity" do
      scenario "they can change the geography from region to country" do
        activity = create(:activity,
          geography: :recipient_region,
          recipient_country: nil,
          organisation: user.organisation)
        activity_path = organisation_activity_details_path(activity.organisation, activity)

        visit activity_path
        within(".recipient_region") do
          click_on "Edit"
        end

        expect(page).to have_content t("form.legend.activity.geography")

        choose "Country"
        click_button t("form.button.activity.submit")

        select "Uganda", from: "activity[recipient_country]"
        click_button t("form.button.activity.submit")

        expect(page).to have_current_path(activity_path)
        expect(page).not_to have_content t("summary.label.activity.recipient_region")
        within(".recipient_country") do
          expect(page).to have_content "Uganda"
        end
      end

      scenario "they can change the geography from country to region" do
        activity = create(:activity,
          geography: :recipient_country,
          recipient_region: nil,
          recipient_country: "AG",
          organisation: user.organisation)
        activity_path = organisation_activity_details_path(activity.organisation, activity)

        visit activity_path
        within(".recipient_country") do
          click_on "Edit"
        end

        expect(page).to have_content t("form.legend.activity.geography")

        choose "Region"
        click_button t("form.button.activity.submit")
        select "Developing countries, unspecified", from: "activity[recipient_region]"
        click_button t("form.button.activity.submit")

        expect(page).to have_current_path(activity_path)
        expect(page).not_to have_content t("summary.label.activity.recipient_country")
        within(".recipient_region") do
          expect(page).to have_content "Developing countries, unspecified"
        end
      end
    end
  end
end
