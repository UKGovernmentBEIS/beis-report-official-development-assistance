RSpec.feature "Users can edit a transaction" do
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
    let!(:transaction) { create(:transaction, parent_activity: activity, report: report) }

    scenario "editing a transaction on a programme" do
      visit activities_path

      click_on(activity.title)

      expect(page).to have_content(transaction.value)

      within("##{transaction.id}") do
        click_on(t("default.link.edit"))
      end

      fill_in_transaction_form(
        description: "This money will be buying some books for students",
        transaction_type: "Expenditure",
        date_day: "1",
        date_month: "1",
        date_year: "2020",
        value: "2000.51",
        disbursement_channel: "Aid in kind: Donors manage funds themselves",
        currency: "US Dollar"
      )

      expect(page).to have_content(t("action.transaction.update.success"))
    end

    scenario "transaction update is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit activities_path

        click_on(activity.title)

        expect(page).to have_content(transaction.value)

        within("##{transaction.id}") do
          click_on(t("default.link.edit"))
        end

        fill_in_transaction_form(
          description: "This money will be buying some books for students",
          transaction_type: "Expenditure",
          date_day: "1",
          date_month: "1",
          date_year: "2020",
          value: "2000.51",
          disbursement_channel: "Aid in kind: Donors manage funds themselves",
          currency: "US Dollar"
        )

        auditable_event = PublicActivity::Activity.find_by(trackable_id: transaction.id)
        expect(auditable_event.key).to eq "transaction.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end
  end

  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:activity) { create(:project_activity, organisation: user.organisation) }
    let(:transaction) { create(:transaction, parent_activity: activity) }
    let(:report) { create(:report, organisation: activity.organisation, fund: activity.associated_fund) }

    before { authenticate!(user: user) }

    context "when the transaction can be edited" do
      before do
        transaction.update(report: report)
        report.update(state: :active)
      end

      scenario "shows the edit link" do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_link t("default.link.edit"), href: edit_activity_transaction_path(activity, transaction)
      end
    end

    context "when the transaction cannot be edited" do
      before { report.update(state: :active) }

      scenario "does not show the edit link" do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).not_to have_link t("default.link.edit"), href: edit_activity_transaction_path(activity, transaction)
      end
    end
  end
end
