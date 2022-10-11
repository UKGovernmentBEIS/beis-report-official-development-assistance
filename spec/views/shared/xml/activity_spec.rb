RSpec.describe "shared/xml/activity" do
  let(:activity) { create(:programme_activity) }

  before do
    reporting_organisation = build(:partner_organisation)
    render partial: "shared/xml/activity",
      locals: {
        activity: activity,
        reporting_organisation: reporting_organisation,
        transactions: nil,
        budgets: nil,
        forecasts: nil,
        commitment: commitment
      }
  end

  context "when there is a commitment" do
    let!(:commitment) { build(:commitment, activity: activity) }
    it "renders the commitment" do
      expect(rendered).to include("<transaction-type code='2'>")
    end
  end

  context "when there is no commitment" do
    let!(:commitment) { nil }
    it "does not render the commitment" do
      expect(rendered).not_to include("<transaction-type code='2'>")
    end
  end
end
