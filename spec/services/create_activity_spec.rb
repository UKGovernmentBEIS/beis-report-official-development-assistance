require "rails_helper"

RSpec.describe CreateActivity do
  let(:organisation) { create(:organisation) }

  describe "#call" do
    let(:result) {
      described_class.new(organisation_id: organisation.id).call
    }

    it "sets the organisation to that of users organisation" do
      expect(result.organisation).to eq organisation
    end

    context "when the activity has yet to be assigned a level" do
      it "uses the organisation as the reporting organisation" do
        expect(result.reporting_organisation).to eq(organisation)
      end
    end

    it "sets the level form_state as the next outstanding step" do
      expect(result.form_state).to eq("identifier")
    end
  end
end
