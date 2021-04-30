require "rails_helper"

RSpec.describe PlannedDisbursementXmlPresenter do
  let(:planned_disbursement) { PlannedDisbursement.unscoped.new }

  describe "#period_start_date" do
    it "returns a date formatted for IATI XML" do
      planned_disbursement.period_start_date = "25 June 2020"
      expect(described_class.new(planned_disbursement).period_start_date).to eq("2020-06-25")
    end
  end

  describe "#period_end_date" do
    it "returns a human readable date" do
      planned_disbursement.period_end_date = "October 20, 2020"
      expect(described_class.new(planned_disbursement).period_end_date).to eq("2020-10-20")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places formatted for IATI XML" do
      planned_disbursement.value = 100_000
      expect(described_class.new(planned_disbursement).value).to eq("100000.00")
    end
  end

  describe "#planned_disbursement_type" do
    it "returns the numeric value for the planned disbursement type" do
      planned_disbursement.planned_disbursement_type = :original
      expect(described_class.new(planned_disbursement).planned_disbursement_type).to eq "1"
    end
  end
end
