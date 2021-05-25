RSpec.feature "users can add benefitting countries as intended beneficiaries" do
  context "when the user is signed as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }
    let(:activity) { create(:project_activity, :at_geography_step, organisation: user.organisation, intended_beneficiaries: nil) }
    let!(:report) { create(:report, :active, fund: activity.associated_fund, organisation: user.organisation) }

    context "after choosing either country or region on the geography step" do
      scenario "the user will be asked if there are other benefitting countries to be added" do
        visit activity_step_path(activity, :geography)
        choose "Country"
        click_button t("form.button.activity.submit")
        expect(page).to have_select(t("form.label.activity.recipient_country"))

        select "China (People's Republic of)"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
        choose "Yes"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.intended_beneficiaries")
      end

      scenario "if there are no other benefitting countries the intended_beneficiaries step will be omitted" do
        visit activity_step_path(activity, :geography)
        choose "Country"
        click_button t("form.button.activity.submit")
        expect(page).to have_select(t("form.label.activity.recipient_country"))

        select "Bolivia"
        click_button t("form.button.activity.submit")
        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
        choose "No"
        click_button t("form.button.activity.submit")
        expect(page).to have_current_path(activity_step_path(activity, :gdi))
      end

      scenario "the user has the option of selecting other intended beneficiaries based on the full list of all countries" do
        visit activity_step_path(activity, :geography)
        choose "Region"
        click_button t("form.button.activity.submit")
        expect(page).to have_select(t("form.label.activity.recipient_region"))

        select "Africa, regional"
        click_button t("form.button.activity.submit")
        expect(activity.reload.recipient_region).to eq("298")

        expect(page).to have_content t("form.legend.activity.requires_additional_benefitting_countries")
        choose "Yes"
        click_button t("form.button.activity.submit")

        expect(page).to have_content t("form.legend.activity.intended_beneficiaries")
        expect(page).to have_selector(".govuk-checkboxes__item", count: 143)
        expect(page).to have_content("Afghanistan")
        expect(page).to have_content("Zimbabwe")
        check "Gambia"
        check "Indonesia"
        check "Yemen"
        click_button t("form.button.activity.submit")
        activity.reload
        expect(activity.intended_beneficiaries).to eq(["GM", "ID", "YE"])
        expect(page).to have_current_path(activity_step_path(activity, :gdi))
      end
    end
  end
end
