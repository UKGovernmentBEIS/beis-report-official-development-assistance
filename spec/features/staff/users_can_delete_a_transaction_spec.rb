RSpec.feature "Users can delete a transaction" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  let!(:activity) { create(:programme_activity) }
  let!(:report) { create(:report, :active, organisation: delivery_partner_user.organisation, fund: activity.associated_fund) }
  let!(:transaction) { create(:transaction, parent_activity: activity, report: report) }

  context "when the user belongs to BEIS" do
    before { authenticate!(user: beis_user) }

    scenario "deleting a transaction on a programme" do
      PublicActivity.with_tracking do
        visit organisation_activity_path(activity.organisation, activity)

        within("##{transaction.id}") do
          click_on(t("default.link.edit"))
        end

        expect { click_on t("default.button.delete") }.to change { Transaction.count }.by(-1)

        expect(page).to have_content(t("action.transaction.destroy.success"))

        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "transaction.destroy"
        expect(auditable_event.owner_id).to eq beis_user.id
        expect(auditable_event.trackable_id).to eq transaction.id
        expect(auditable_event.parameters).to eq({activity_id: activity.id})
      end
    end
  end

  context "when signed in as a delivery partner" do
    before { authenticate!(user: delivery_partner_user) }

    let!(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }

    scenario "deleting a transaction on a project" do
      PublicActivity.with_tracking do
        visit organisation_activity_path(activity.organisation, activity)

        within("##{transaction.id}") do
          click_on(t("default.link.edit"))
        end

        expect { click_on t("default.button.delete") }.to change { Transaction.count }.by(-1)

        expect(page).to have_content(t("action.transaction.destroy.success"))

        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "transaction.destroy"
        expect(auditable_event.owner_id).to eq delivery_partner_user.id
        expect(auditable_event.trackable_id).to eq transaction.id
      end
    end
  end
end
