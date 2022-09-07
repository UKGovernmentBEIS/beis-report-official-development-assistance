RSpec.feature "Users can view an activity's other funding" do
  let(:user) { create(:partner_organisation_user) }
  let(:matched_effort_provider) { create(:matched_effort_provider) }
  let(:external_income_provider) { create(:external_income_provider) }
  let!(:activity) { create(:project_activity, organisation: user.organisation) }

  let!(:matched_effort) do
    create(:matched_effort,
      activity: activity,
      organisation: matched_effort_provider,
      funding_type: "in_kind",
      category: "staff_time",
      committed_amount: 200_000)
  end

  let!(:external_income) do
    create(:external_income,
      activity: activity,
      organisation: external_income_provider,
      financial_quarter: 1,
      financial_year: 2021,
      amount: 150_000)
  end

  context "when the user is signed in as a partner organisation user" do
    before { authenticate!(user: user) }

    it "lists the matched efforts" do
      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.other_funding")

      expect(page).to have_content(matched_effort_provider.name)
      expect(page).to have_content("In kind")
      expect(page).to have_content("Staff time")
      expect(page).to have_content("£200,000.00")
    end

    it "lists the external incomes" do
      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.other_funding")

      expect(page).to have_content(external_income_provider.name)
      expect(page).to have_content("Q1 2021-2022")
      expect(page).to have_content("£150,000.00")
    end
  end

  context "when the user is signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }

    it "lists the matched efforts" do
      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.other_funding")

      expect(page).to have_content(matched_effort_provider.name)
    end

    it "lists the external incomes" do
      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.other_funding")

      expect(page).to have_content(external_income_provider.name)
    end
  end

  context "when the user is not a member of the activity's organisation" do
    before { authenticate!(user: create(:partner_organisation_user)) }

    it "does not allow the user to view the funding" do
      visit organisation_activity_other_funding_path(activity.organisation, activity)

      expect(page).to_not have_content(matched_effort_provider.name)
      expect(page).to_not have_content(external_income_provider.name)
    end
  end
end
