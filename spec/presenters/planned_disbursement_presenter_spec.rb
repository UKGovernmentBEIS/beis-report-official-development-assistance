require "rails_helper"

RSpec.describe PlannedDisbursementPresenter do
  let(:planned_disbursement) { build_stubbed(:planned_disbursement) }

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(planned_disbursement).value).to eq("£100,000.00")
    end
  end
end
