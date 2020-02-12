require "rails_helper"

RSpec.describe CreateProjectActivity do
  let(:organisation) { create(:organisation) }
  let(:programme) { create(:programme_activity) }
  let(:user) { create(:fund_manager) }

  describe "#call" do
    let(:result) { described_class.new(organisation_id: organisation.id, programme_id: programme.id, user: user).call }

    it "sets the Organisation" do
      expect(result.organisation).to eq(organisation)
    end

    it "sets the parent Activity to the programme" do
      expect(result.activity).to eq(programme)
    end

    it "sets the initial wizard_status" do
      expect(result.wizard_status).to eq("identifier")
    end

    it "sets the Activity level to 'project'" do
      expect(result.level).to eq("project")
    end

    it "sets the funding organisation details" do
      expect(result.funding_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(result.funding_organisation_reference).to eq("GB-GOV-13")
      expect(result.funding_organisation_type).to eq("10")
    end

    it "sets the accountable organisation details" do
      expect(result.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(result.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(result.accountable_organisation_type).to eq("10")
    end

    context "when the user is a delivery partner" do
      let(:user) { create(:delivery_partner) }

      it "sets the extending organisation to the user's organisation" do
        expect(result.extending_organisation).to eq(user.organisation)
      end
    end

    context "when the user is a fund manager" do
      it "does not set the extending organisation" do
        expect(result.extending_organisation).to be_nil
      end
    end
  end
end
