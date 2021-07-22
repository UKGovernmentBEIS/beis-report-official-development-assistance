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
      visit organisation_activity_path(activity.organisation, activity)

      expect(page).to have_content(transaction.value)

      within("##{transaction.id}") do
        click_on(t("default.link.edit"))
      end

      fill_in_transaction_form(
        value: "2000.51",
        financial_quarter: "4",
        financial_year: "2019-2020",
      )

      expect(page).to have_content(t("action.transaction.update.success"))
    end

    scenario "transaction update is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_content(transaction.value)

        within("##{transaction.id}") do
          click_on(t("default.link.edit"))
        end

        fill_in_transaction_form(
          value: "2000.51",
          financial_quarter: "4",
          financial_year: "2019-2020",
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

      scenario "can be edited, with 'change history'" do
        visit organisation_activity_path(activity.organisation, activity)

        expect(page).to have_link t("default.link.edit"), href: edit_activity_transaction_path(activity, transaction)

        within ".transactions" do
          expect(page).to have_content("£110.01")
          click_link("Edit")
        end

        fill_in "transaction[value]", with: 221.12

        click_on(t("default.button.submit"))

        within ".transactions" do
          expect(page).to have_content("£221.12")
        end
        expect_to_see_change_recorded_in_activitys_change_history("110.01", "221.12")
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

  def expect_to_see_change_recorded_in_activitys_change_history(previous_value, new_value)
    click_link("Change history")
    within(".historical-events .transaction") do
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
