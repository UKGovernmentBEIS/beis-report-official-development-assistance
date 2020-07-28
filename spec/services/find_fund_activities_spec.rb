require "rails_helper"

RSpec.describe FindFundActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:organisation) }

  let!(:organisation_fund) { create(:fund_activity, organisation: other_organisation) }
  let!(:other_fund) { create(:fund_activity) }

  describe "#call" do
    context "when the organisation is the service owner" do
      it "returns all fund activities" do
        result = described_class.new(organisation: service_owner, user: user).call

        expect(result).to match_array [organisation_fund, other_fund]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns fund activities for this organisation" do
        result = described_class.new(organisation: other_organisation, user: user).call

        expect(result).to match_array [organisation_fund]
      end
    end
  end
end
