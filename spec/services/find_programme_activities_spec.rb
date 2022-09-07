require "rails_helper"

RSpec.describe FindProgrammeActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:delivery_partner_organisation) }

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
        partner_organisation = create(:delivery_partner_organisation)
        source_fund_code = 1
        programme = create(:programme_activity, source_fund_code: source_fund_code, extending_organisation: partner_organisation)
        programme_from_another_fund = create(:programme_activity, source_fund_code: 2, extending_organisation: partner_organisation)

        result = described_class.new(organisation: partner_organisation, user: user, fund_code: source_fund_code).call

        expect(result).to include programme
        expect(result).not_to include programme_from_another_fund
      end
    end
  end
end
