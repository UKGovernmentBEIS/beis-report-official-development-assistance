RSpec.feature "Users can manage Sectors" do
  context "when they belong to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    context "with a new activity" do
      scenario "they can provide the sector category" do
        activity = create(:activity, :at_identifier_step, identifier: "GCRF", organisation: user.organisation)
        visit activity_step_path(activity, :sector_category)
        choose "Basic Education"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_current_path(activity_step_path(activity, :sector))
        expect(page).to have_content I18n.t("page_title.activity_form.show.sector", sector_category: activity.reload.sector_category_name, level: activity.level)
      end
    end

    context "with an existing activity" do
      let(:activity) { create(:activity, organisation: user.organisation) }

      scenario "when editing the sector category it resets the sector value, redirects to the sector step and then the summary" do
        visit organisation_activity_path(user.organisation, activity)
        within ".sector" do
          click_on "Edit"
        end

        expect(page).to have_current_path(activity_step_path(activity, :sector_category))

        choose "Basic Education"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_current_path(activity_step_path(activity, :sector, editing_until: :sector))
        expect(activity.reload.sector).to be_nil

        choose "School feeding"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_current_path(organisation_activity_path(user.organisation, activity))
      end

      scenario "when editing the sector it resets the sector value, redirects to sector category step followed by sector and then the summary" do
        visit organisation_activity_path(user.organisation, activity)
        within ".sector" do
          click_on "Edit"
        end

        expect(page).to have_current_path(activity_step_path(activity, :sector_category))

        choose "Basic Education"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_current_path(activity_step_path(activity, :sector, editing_until: :sector))
        expect(activity.reload.sector).to be_nil

        choose "School feeding"
        click_button I18n.t("form.activity.submit")

        expect(page).to have_current_path(organisation_activity_path(user.organisation, activity))
      end
    end
  end
end
