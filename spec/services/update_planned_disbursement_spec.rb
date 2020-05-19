require "rails_helper"

RSpec .describe UpdatePlannedDisbursement do
  let(:planned_disbursement) { create(:planned_disbursement) }

  describe "#call" do
    it "sets the attributes of the planned disbursement" do
      attributes = attributes_for(:planned_disbursement, receiving_organisation_name: "An Organisation")

      result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: attributes)

      expect(result.object.receiving_organisation_name).to eq("An Organisation")
    end

    it "returns a Result with the success set to true" do
      allow(planned_disbursement).to receive(:valid?).and_return(true)
      allow(planned_disbursement).to receive(:save!).and_return(true)

      result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: {})

      expect(result.success?).to be true
    end

    subject { described_class.new(planned_disbursement: planned_disbursement) }
    it_behaves_like "sanitises monetary field"

    context "when the planned disbursment is not valid" do
      it "returns a Result with the success set to false" do
        allow(planned_disbursement).to receive(:valid?).and_return(false)

        result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: {})

        expect(result.success?).to be false
      end
    end
  end
end
