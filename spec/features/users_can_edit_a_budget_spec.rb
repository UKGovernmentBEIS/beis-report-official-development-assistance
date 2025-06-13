RSpec.describe "Users can edit a budget" do
  before do
    authenticate!(user: user)
    freeze_time
  end

  after { logout }

  shared_examples "editable and deletable budget" do
    before do
      visit organisation_activity_path(activity.organisation, activity)
    end

    scenario "a budget can be successfully edited and a history event added" do
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      expect(page).to have_content("Edit budget for FY 2018-2019")
      expect(page).to have_content("Current budget: £10.00")
      fill_in "budget[value]", with: "20"

      expect {
        click_on t("default.button.submit")
      }.to change { HistoricalEvent.count }.by(1)

      expect(page).to have_content("Budget successfully updated. Current budget of FY 2018-2019 is now £20.00")
      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end

      historical_event = HistoricalEvent.last

      expect(historical_event.user_id).to eq(user.id)
      expect(historical_event.activity_id).to eq(activity.id)
      expect(historical_event.value_changed).to eq("value")
      expect(historical_event.new_value).to eq(20)
      expect(historical_event.previous_value).to eq(budget.value)
      expect(historical_event.reference).to eq("Change to Budget")
      expect(historical_event.report).to eq(defined?(report) && report)
    end

    scenario "a budget can be successfully deleted" do
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      click_on t("default.button.delete")

      expect(page).to have_content(t("action.budget.destroy.success"))
      expect(page).to_not have_content("10.00")

      expect { budget.reload }.to raise_error { ActiveRecord::RecordNotFound }
    end

    scenario "a budget cannot be edited when value is not changed and a comment is added" do
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[audit_comment]", with: "A comment"

      click_on t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content("Value must be updated when adding a comment")
    end

    scenario "the revision history of a budget can be viewed" do
      within("##{budget.id}") do
        expect(page).to have_content("£10.00")
        expect(page).to have_content("None")
      end

      travel_to(Date.tomorrow)
      authenticate!(user: user)

      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: "20"
      click_on t("default.button.submit")

      expect(page).to have_content("Budget successfully updated. Current budget of FY 2018-2019 is now £20.00")
      within("##{budget.id}") do
        expect(page).to have_content("£20.00")
        expect(page).to have_link("1 revision", href: activity_budget_revisions_path(budget.parent_activity_id, budget))
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: "5"
      fill_in "budget[audit_comment]", with: "This budget has been reduced"
      click_on t("default.button.submit")

      expect(page).to have_content("Budget successfully updated. Current budget of FY 2018-2019 is now £5.00")
      within("##{budget.id}") do
        expect(page).to have_content("£5.00")
        click_on "2 revisions"
      end

      expect(page).to have_content("Budget revisions")
      expect(page).to have_content("Current budget: £5.00")

      within("tbody") do
        expect(page.all("tr").count).to be 3
      end

      original_row = page.find("th", text: "Original").ancestor("tr")
      within(original_row) do
        expect(page).to have_content("£10.00")
        expect(page.all("td", exact_text: "").count).to be 2
        expect(page).to have_content(I18n.l(Date.yesterday))
      end

      revision_1_row = page.find("th", text: "Revision 1").ancestor("tr")
      within(revision_1_row) do
        expect(page).to have_content("£20.00")
        expect(page).to have_content("+£10.00")
        expect(page).to have_content(I18n.l(Date.today))
      end

      revision_2_row = page.find("th", text: "Revision 2").ancestor("tr")
      within(revision_2_row) do
        expect(page).to have_content("£5.00")
        expect(page).to have_content("-£15.00")
        expect(page).to have_content(I18n.l(Date.today))
        expect(page).to have_content("This budget has been reduced")
      end
    end

    scenario "validation errors work as expected" do
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: ""

      click_on t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content(t("activerecord.errors.models.budget.attributes.value.blank"))
      expect(page).to have_content("Current budget: £10.00")
    end
  end

  shared_examples "non-editable budget" do
    scenario "a budget cannot be edited" do
      visit organisation_activity_path(activity.organisation, activity)

      within("##{budget.id}") do
        expect(page).to_not have_content(t("default.link.edit"))
      end
    end
  end

  context "when signed in as a beis user" do
    let(:user) { create(:beis_user) }
    let!(:budget) { create(:budget, parent_activity: activity, value: "10", financial_year: 2018) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      include_examples "editable and deletable budget"
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      include_examples "editable and deletable budget"
    end

    context "when the activity is a project" do
      let(:programme_activity) { create(:programme_activity, organisation: user.organisation) }
      let(:activity) { create(:project_activity, parent: programme_activity) }

      include_examples "non-editable budget"
    end
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }
    let!(:budget) { create(:budget, parent_activity: activity, value: "10", financial_year: 2018, report: report) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, extending_organisation: user.organisation) }

      include_examples "non-editable budget"
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }

      include_examples "editable and deletable budget"
    end
  end
end
