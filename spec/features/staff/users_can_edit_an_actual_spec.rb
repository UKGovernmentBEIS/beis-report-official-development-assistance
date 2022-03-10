RSpec.feature "Users can edit an actual" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit activity_step_path(double(Activity, id: "123"), :identifier)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    before { authenticate!(user: user) }
    let(:user) { create(:beis_user) }
    let!(:activity) { create(:programme_activity, organisation: user.organisation) }
    let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }
    let!(:actual) { create(:actual, parent_activity: activity, report: report) }

    scenario "editing an actual on a programme" do
      visit organisation_activity_path(activity.organisation, activity)

      expect(page).to have_content(actual.value)

      within("##{actual.id}") do
        click_on(t("default.link.edit"))
      end

      fill_in_actual_form(
        value: "2000.51",
        financial_quarter: "4",
        financial_year: "2019-2020"
      )

      expect(page).to have_content(t("action.actual.update.success"))
    end
  end

  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:activity) { create(:project_activity, organisation: user.organisation) }
    let(:actual) { create(:actual, parent_activity: activity) }
    let(:report) { create(:report, organisation: activity.organisation, fund: activity.associated_fund) }

    before { authenticate!(user: user) }

    context "when the actual can be edited" do
      before do
        actual.update(report: report)
        report.update(state: :active)
      end

      scenario "can be edited, with 'change history'" do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_link t("default.link.edit"), href: edit_activity_actual_path(activity, actual)

        within ".actuals" do
          expect(page).to have_content("£110.01")
          click_link("Edit")
        end

        fill_in "Actual amount", with: "notanumber"
        click_on(t("default.button.submit"))

        expect(page).to have_content("Value must be a valid number")
        expect(page).to have_field("Actual amount", with: "notanumber")

        fill_in "Actual amount", with: 221.12

        click_on(t("default.button.submit"))

        within ".actuals" do
          expect(page).to have_content("£221.12")
        end
        expect_to_see_change_recorded_in_activitys_change_history("110.01", "221.12")
      end
    end

    context "when the actual cannot be edited" do
      before { report.update(state: :active) }

      scenario "does not show the edit link" do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).not_to have_link t("default.link.edit"), href: edit_activity_actual_path(activity, actual)
      end
    end
  end

  def expect_to_see_change_recorded_in_activitys_change_history(previous_value, new_value)
    click_link("Change history")
    within(".historical-events .actual") do
      expect(page).to have_css(".property", text: "value")
      expect(page).to have_css(".previous-value", text: previous_value)
      expect(page).to have_css(".new-value", text: new_value)
      expect(page).to have_css(
        ".report a[href='#{report_path(report)}']",
        text: report.financial_quarter_and_year
      )
    end
  end
end
