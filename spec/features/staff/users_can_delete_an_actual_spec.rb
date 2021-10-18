RSpec.feature "Users can delete an actual" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  let!(:activity) { create(:programme_activity) }
  let!(:report) { create(:report, organisation: delivery_partner_user.organisation, fund: activity.associated_fund) }
  let!(:actual) { create(:actual, parent_activity: activity, report: report) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: beis_user) }

    scenario "deleting a actual on a programme" do
      visit organisation_activity_path(activity.organisation, activity)

      within("##{actual.id}") do
        click_on(t("default.link.edit"))
      end

      expect { click_on t("default.button.delete") }.to change { Actual.count }.by(-1)
      expect(page).to have_content(t("action.actual.destroy.success"))
    end
  end

  context "when signed in as a delivery partner" do
    before { authenticate!(user: delivery_partner_user) }

    let!(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }

    scenario "deleting an actual on a project" do
      visit organisation_activity_path(activity.organisation, activity)

      within("##{actual.id}") do
        click_on(t("default.link.edit"))
      end

      expect { click_on t("default.button.delete") }.to change { Actual.count }.by(-1)
      expect(page).to have_content(t("action.actual.destroy.success"))
    end
  end
end
