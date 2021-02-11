require "rails_helper"

RSpec.describe CreateProgramme do
  let(:fund) { create(:fund_activity, :gcrf) }
  let(:service_owner) { create(:beis_organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }

  describe "#call" do
    let(:result) {
      described_class.new(
        organisation_id: organisation.id,
        source_fund_id: fund.source_fund.id
      ).call
    }

    it "creates a programme-level activity with the expected defaults" do
      expect(result.level).to eq("programme")
      expect(result.organisation).to eq(service_owner)
      expect(result.reporting_organisation).to eq(organisation)
      expect(result.extending_organisation).to eq(service_owner)
      expect(result.accountable_organisation_name).to eq(service_owner.name)
      expect(result.accountable_organisation_reference).to eq(service_owner.iati_reference)
      expect(result.accountable_organisation_type).to eq(service_owner.organisation_type)
      expect(result.form_state).to eq("identifier")

      expect(result.source_fund).to eq(fund.source_fund)
      expect(result.parent).to eq(fund)
    end
  end
end
