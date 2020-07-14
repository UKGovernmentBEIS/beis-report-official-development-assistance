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
    let!(:activity) { create(:fund_activity, organisation: user.organisation) }
    let!(:transaction) { create(:transaction, parent_activity: activity) }

    scenario "editing a transaction on a fund" do
      visit activities_path

      click_on(activity.title)

      expect(page).to have_content(transaction.value)

      within("##{transaction.id}") do
        click_on(I18n.t("default.link.edit"))
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

      expect(page).to have_content(I18n.t("action.transaction.update.success"))
    end

    scenario "transaction update is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit activities_path

        click_on(activity.title)

        expect(page).to have_content(transaction.value)

        within("##{transaction.id}") do
          click_on(I18n.t("default.link.edit"))
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

    scenario "going back to the previous page" do
      visit activities_path

      click_on(activity.title)

      expect(page).to have_content(transaction.value)

      within("##{transaction.id}") do
        click_on(I18n.t("default.link.edit"))
      end
      click_on(I18n.t("default.link.back"))

      expect(page).to have_content(activity.title)
    end
  end
end
