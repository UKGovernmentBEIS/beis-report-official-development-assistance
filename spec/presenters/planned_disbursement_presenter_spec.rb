require "rails_helper"

RSpec.describe PlannedDisbursementPresenter do
  let(:planned_disbursement) { build_stubbed(:planned_disbursement) }

  describe "#planned_disbursement_type" do
    it "returns the I18n string for the planned_disbursement_type" do
      expect(described_class.new(planned_disbursement).planned_disbursement_type).to eq("Original")
    end
  end

  describe "#period_start_date" do
    it "returns a human readable date" do
      planned_disbursement.period_start_date = "2020-06-25"
      expect(described_class.new(planned_disbursement).period_start_date).to eq("25 Jun 2020")
    end
  end

  describe "#period_end_date" do
    it "returns a human readable date" do
      planned_disbursement.period_end_date = "2020-10-20"
      expect(described_class.new(planned_disbursement).period_end_date).to eq("20 Oct 2020")
    end
  end

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(planned_disbursement).value).to eq("£100,000.00")
    end
  end

  describe "#currency" do
    it "returns the I18n string for the currency" do
      expect(described_class.new(planned_disbursement).currency).to eq("Pound Sterling")
    end
  end
end
