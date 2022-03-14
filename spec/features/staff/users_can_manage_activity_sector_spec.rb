RSpec.feature "Users can manage Sectors" do
  context "when they belong to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    context "with a new activity" do
      scenario "they can provide the sector category" do
        activity = create(:fund_activity, :at_identifier_step, delivery_partner_identifier: "GCRF", organisation: user.organisation)
        visit activity_step_path(activity, :sector_category)
        choose "Basic Education"
        click_button "Continue"

        expect(page).to have_current_path(activity_step_path(activity, :sector))
        expect(page).to have_content t("form.legend.activity.sector", sector_category: t("activity.sector_category.#{activity.reload.sector_category}"), level: "fund (level A)")
      end
    end

    context "with an existing activity" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      scenario "they can edit the sector by changing the sector category and sector and retruning to the summary" do
        visit organisation_activity_details_path(user.organisation, activity)
        within ".sector" do
          click_on "Edit"
        end

        expect(page).to have_current_path(activity_step_path(activity, :sector_category))

        choose "Basic Education"
        click_button "Continue"
        choose "Early childhood education"
        click_button "Continue"

        expect(page).to have_current_path(organisation_activity_details_path(user.organisation, activity))
        within ".sector" do
          expect(page).to have_content "Early childhood education"
        end
      end
    end
  end
end
