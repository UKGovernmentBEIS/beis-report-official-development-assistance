RSpec.feature "Users can view commitment values" do
  before do
    authenticate!(user: user)
  end

  let(:user) { create(:partner_organisation_user) }
  let(:activity) { create(:project_activity, organisation: user.organisation) }

  context "when there is a commitment value" do
    scenario "the commitment is shown" do
      commitment = create(:commitment, value: 100_000, activity_id: activity.id)
      presenter = CommitmentPresenter.new(commitment)

      visit organisation_activity_financials_path(user.organisation, activity)

      expect(page).to have_content "Commitment"
      expect(page).to have_css("table#commitment")
      expect(page).to have_content presenter.value
      expect(page).to have_content presenter.financial_quarter_and_year
    end
  end

  context "when there is not a commitment value" do
    scenario "the commitment is not shown" do
      visit organisation_activity_financials_path(user.organisation, activity)

      expect(page).not_to have_content "Commitment"
      expect(page).not_to have_css("table#commitment")
    end
  end
end
