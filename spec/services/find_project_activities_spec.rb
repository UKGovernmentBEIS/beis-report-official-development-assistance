require "rails_helper"

RSpec.describe FindProjectActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:delivery_partner_organisation) }

  let!(:fund_1_organisation_project) { create(:project_activity, organisation: other_organisation, source_fund_code: 1) }
  let!(:fund_2_organisation_project) { create(:project_activity, organisation: other_organisation, source_fund_code: 2) }
  let!(:other_project) { create(:project_activity, source_fund_code: 1) }

  describe "#call" do
    context "when the organisation is the service owner" do
      it "returns all project activities" do
        result = described_class.new(organisation: service_owner, user: user).call

        expect(result).to match_array [fund_1_organisation_project, fund_2_organisation_project, other_project]
      end

      it "filters by the fund code" do
        result = described_class.new(organisation: service_owner, user: user, fund_code: 1).call

        expect(result).to match_array [fund_1_organisation_project, other_project]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns project activities for this organisation" do
        result = described_class.new(organisation: other_organisation, user: user).call

        expect(result).to match_array [fund_1_organisation_project, fund_2_organisation_project]
      end

      it "filters by the fund code" do
        result = described_class.new(organisation: other_organisation, user: user, fund_code: 1).call

        expect(result).to match_array [fund_1_organisation_project]
      end
    end
  end
end
