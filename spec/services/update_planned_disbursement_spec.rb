require "rails_helper"

RSpec .describe UpdatePlannedDisbursement do
  let(:planned_disbursement) { create(:planned_disbursement) }

  describe "#call" do
    it "sets the attributes of the planned disbursement" do
      attributes = attributes_for(:planned_disbursement, receiving_organisation_name: "An Organisation")

      result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: attributes)

      expect(result.object.receiving_organisation_name).to eq("An Organisation")
    end

    context "when financial quarter and year are provided" do
      it "sets the period start and end dates" do
        financial_quarter = "1"
        financial_year = "2020"
        result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: {financial_quarter: financial_quarter, financial_year: financial_year})
        expect(result.object.period_start_date).to eq "2020-04-01".to_date
        expect(result.object.period_end_date).to eq "2020-06-30".to_date
      end
    end

    context "when start and end date are provided" do
      it "sets the financial quarter and year" do
        start_date = "1 April 2020"
        end_date = "30 June 2020"
        result = described_class.new(planned_disbursement: planned_disbursement).call(attributes: {period_start_date: start_date, period_end_date: end_date})
        expect(result.object.financial_quarter).to eq 1
        expect(result.object.financial_year).to eq 2020
      end
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
