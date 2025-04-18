RSpec.describe "shared/xml/activity" do
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

  describe "commitment" do
    let(:activity) { create(:programme_activity) }

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

  describe "Other identifier for BEIS to DSIT" do
    context "when hybrid_beis_dsit_activity is true" do
      let(:activity) { create(:programme_activity, hybrid_beis_dsit_activity: true) }
      let!(:commitment) { nil }

      it "includes the other-identifier element" do
        expect(rendered).to include("<other-identifier ref='GB-GOV-13' type='B1'>")
        expect(rendered).to include("<owner-org ref='GB-GOV-13'>")
        expect(rendered).to include("<narrative xml:lang='en'>DSIT previous reporting-org identifier</narrative")
      end
    end

    context "when hybrid_beis_dsit_activity is false" do
      let(:activity) { create(:programme_activity, hybrid_beis_dsit_activity: false) }
      let!(:commitment) { nil }

      it "does not include the other-identifier element" do
        expect(rendered).not_to include("<other-identifier ref='GB-GOV-13'type='B1'>")
      end
    end
  end

  describe "activity-scope" do
    context "when there are benefitting countries" do
      let(:commitment) { nil }
      let(:activity) { build(:project_activity, :gcrf_funded, benefitting_countries: %w[ZA]) }

      it "inlcudes the scope element" do
        expect(rendered).to include("<activity-scope")
      end
    end

    context "when there are no benefitting countries" do
      let(:commitment) { nil }
      let(:activity) { build(:project_activity, :gcrf_funded, benefitting_countries: nil) }

      it "does not include the scope element" do
        expect(rendered).not_to include("<activity-scope")
      end
    end
  end
end
