RSpec.feature "Users can view an activity's other funding" do
  let(:user) { create(:delivery_partner_user) }
  let(:matched_effort_provider) { create(:matched_effort_provider) }
  let!(:activity) { create(:project_activity, organisation: user.organisation) }

  let!(:matched_effort) do
    create(:matched_effort,
      activity: activity,
      organisation: matched_effort_provider,
      funding_type: "in_kind",
      category: "staff_time",
      committed_amount: 200_000)
  end

  context "when the user is signed in as a delivery partner" do
    before { authenticate!(user: user) }

    it "lists the matched efforts" do
      visit organisation_activity_path(activity.organisation, activity)
      click_on t("tabs.activity.other_funding")

      expect(page).to have_content(matched_effort_provider.name)
      expect(page).to have_content("In kind")
      expect(page).to have_content("Staff time")
      expect(page).to have_content("£200,000.00")
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
  end

  context "when the user is not a member of the activity's organisation" do
    before { authenticate!(user: create(:delivery_partner_user)) }

    it "does not allow the user to view the funding" do
      visit organisation_activity_other_funding_path(activity.organisation, activity)

      expect(page).to_not have_content(matched_effort_provider.name)
    end
  end
end
