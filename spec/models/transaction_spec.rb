require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:activity) { build(:activity) }

  describe "validations" do
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:receiving_organisation_name) }
    it { should validate_presence_of(:receiving_organisation_type) }

    it { should validate_attribute(:date).with(:date_within_boundaries) }
    it { should validate_attribute(:date).with(:date_not_in_future) }

    context "when the activity belongs to a delivery partner organisation" do
      before { activity.update(organisation: build_stubbed(:delivery_partner_organisation)) }

      it "should validate the prescence of report" do
        transaction = build_stubbed(:transaction, parent_activity: activity, report: nil)
        expect(transaction.valid?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      before { activity.update(organisation: build_stubbed(:beis_organisation)) }

      it "should not validate the prescence of report" do
        transaction = build_stubbed(:transaction, parent_activity: activity, report: nil)
        expect(transaction.valid?).to be true
      end
    end
  end

  describe "sanitation" do
    it { should strip_attribute(:receiving_organisation_reference) }
  end

  describe "#value" do
    context "value must be a maximum of 99,999,999,999.00 (100 billion minus one)" do
      it "allows the maximum possible value" do
        transaction = build(:transaction, parent_activity: activity, value: 99_999_999_999.00)
        expect(transaction.valid?).to be true
      end

      it "allows one penny" do
        transaction = build(:transaction, parent_activity: activity, value: 0.01)
        expect(transaction.valid?).to be true
      end

      it "does not allow a value of 0" do
        transaction = build(:transaction, parent_activity: activity, value: 0)
        expect(transaction.valid?).to be false
      end

      it "does not allow a value of more than 99,999,999,999.00" do
        transaction = build(:transaction, parent_activity: activity, value: 100_000_000_000.00)
        expect(transaction.valid?).to be false
      end

      it "allows a value between 1 and 99,999,999,999.00" do
        transaction = build(:transaction, parent_activity: activity, value: 500_000.00)
        expect(transaction.valid?).to be true
      end

      it "allows a negative value" do
        transaction = build(:transaction, parent_activity: activity, value: -500_000.00)
        expect(transaction.valid?).to be true
      end
    end
  end

  describe "#financial_quarter_and_year" do
    it "returns the financial quarter and year that the transaction's date occurs in" do
      transaction = build(:transaction, financial_quarter: 1, financial_year: 2020)

      expect(transaction.financial_quarter_and_year).to eq("Q1 2020-2021")
    end

    it "returns nil if the date is nil" do
      transaction = build(:transaction, financial_quarter: nil, financial_year: 2020)

      expect(transaction.financial_quarter_and_year).to eq(nil)
    end
  end
end
