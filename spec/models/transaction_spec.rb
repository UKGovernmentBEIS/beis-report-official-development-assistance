require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:activity) { build(:activity) }

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }
    it { should_not validate_presence_of(:disbursement_channel) }
    it { should validate_presence_of(:providing_organisation_name) }
    it { should validate_presence_of(:providing_organisation_type) }
    it { should validate_presence_of(:receiving_organisation_name) }
    it { should validate_presence_of(:receiving_organisation_type) }
  end

  describe "sanitation" do
    it { should strip_attribute(:providing_organisation_reference) }
    it { should strip_attribute(:receiving_organisation_reference) }
  end

  describe "#value" do
    context "value must be between 1 and 99,999,999,999.00 (100 billion minus one)" do
      it "allows the maximum possible value" do
        transaction = build(:transaction, parent_activity: activity, value: 99_999_999_999.00)
        expect(transaction.valid?).to be true
      end

      it "allows the minimum possible value" do
        transaction = build(:transaction, parent_activity: activity, value: 0.01)
        expect(transaction.valid?).to be true
      end

      it "does not allow a value of less than 0.01" do
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
    end
  end

  describe "#date" do
    context "date must not be in the future" do
      it "allows a date in the past" do
        transaction = build(:transaction, parent_activity: activity, date: 1.year.ago)
        expect(transaction.valid?).to be true
      end

      it "does not allow a date in the future" do
        transaction = build(:transaction, parent_activity: activity, date: 1.year.from_now)
        expect(transaction.valid?).to be false
        expect(transaction.errors[:date]).to include "Date must not be in the future"
      end

      it "allows today's date" do
        transaction = build(:transaction, parent_activity: activity, date: Date.today)
        expect(transaction.valid?).to be true
      end

      it "allows a nil date" do
        transaction = build(:transaction, parent_activity: activity, date: Date.today)
        expect(transaction.valid?).to be true
      end
    end

    context "when the value is more than 10 years in the past" do
      it "is not valid" do
        transaction = build(:transaction, date: 10.years.ago)
        expect(transaction).to be_invalid
      end
    end
  end
end
