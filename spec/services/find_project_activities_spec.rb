require "rails_helper"

RSpec.describe FindProjectActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:delivery_partner_organisation) }

  let!(:organisation_project) { create(:project_activity, organisation: other_organisation) }
  let!(:other_project) { create(:project_activity) }

  describe "#call" do
    context "when the organisation is the service owner" do
      it "returns all project activities" do
        result = described_class.new(organisation: service_owner, user: user).call

        expect(result).to match_array [organisation_project, other_project]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns project activities for this organisation" do
        result = described_class.new(organisation: other_organisation, user: user).call

        expect(result).to match_array [organisation_project]
      end
    end
  end
end
