require "rails_helper"

RSpec.describe FindProgrammeActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:organisation) }

  let!(:extending_organisation_programme) { create(:programme_activity, extending_organisation: other_organisation) }
  let!(:other_programme) { create(:programme_activity) }

  describe "#call" do
    context "when the organisation is the service owner" do
      it "returns all programme activities" do
        result = described_class.new(organisation: service_owner, user: user).call

        expect(result).to match_array [extending_organisation_programme, other_programme]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns programme activities whose extending organisation is this organisation" do
        result = described_class.new(organisation: other_organisation, user: user).call

        expect(result).to match_array [extending_organisation_programme]
      end
    end

    context "when a fund is passed" do
      it "includes only the programmes for the organisaiton and the fund" do
        delivery_partner_organisation = create(:delivery_partner_organisation)
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund, extending_organisation: delivery_partner_organisation)
        programme_from_another_fund = create(:programme_activity, extending_organisation: delivery_partner_organisation)

        result = described_class.new(organisation: delivery_partner_organisation, user: user, fund_id: fund.id).call

        expect(result).to include programme
        expect(result).not_to include programme_from_another_fund
      end
    end
  end
end
