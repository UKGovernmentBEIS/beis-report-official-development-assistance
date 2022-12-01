require "rails_helper"

RSpec.describe FindProjectActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:partner_organisation) }

  let!(:fund_1_organisation_project) { create(:project_activity_with_implementing_organisations, organisation: other_organisation, source_fund_code: 1) }
  let!(:fund_2_organisation_project) { create(:project_activity_with_implementing_organisations, organisation: other_organisation, source_fund_code: 2) }
  let!(:other_project) { create(:project_activity_with_implementing_organisations, source_fund_code: 1) }

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

      context "filtering by `include_ispf_non_oda_activities`" do
        let!(:oda_project) { create(:project_activity, :ispf_funded, organisation: other_organisation, is_oda: true) }
        let!(:non_oda_project) { create(:project_activity, :ispf_funded, organisation: other_organisation, is_oda: false) }

        it "excludes ISPF non-ODA activities by default" do
          result = described_class.new(organisation: service_owner, user: user).call

          expect(result).to match_array [fund_1_organisation_project, fund_2_organisation_project, other_project, oda_project]
        end

        it "includes ISPF non-ODA activities when `include_ispf_non_oda_activities` is true" do
          result = described_class.new(organisation: service_owner, user: user, include_ispf_non_oda_activities: true).call

          expect(result).to match_array [
            fund_1_organisation_project,
            fund_2_organisation_project,
            other_project,
            oda_project,
            non_oda_project
          ]
        end
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

      context "filtering by `include_ispf_non_oda_activities`" do
        let!(:oda_project) { create(:project_activity, :ispf_funded, organisation: other_organisation, is_oda: true) }
        let!(:non_oda_project) { create(:project_activity, :ispf_funded, organisation: other_organisation, is_oda: false) }

        it "excludes ISPF non-ODA activities by default" do
          result = described_class.new(organisation: other_organisation, user: user).call

          expect(result).to match_array [fund_1_organisation_project, fund_2_organisation_project, oda_project]
        end

        it "includes ISPF non-ODA activities when `include_ispf_non_oda_activities` is true" do
          result = described_class.new(organisation: other_organisation, user: user, include_ispf_non_oda_activities: true).call

          expect(result).to match_array [
            fund_1_organisation_project,
            fund_2_organisation_project,
            oda_project,
            non_oda_project
          ]
        end
      end
    end
  end
end
