require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:activity) { build(:activity) }

  describe "validations" do
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:receiving_organisation_name) }
    it { should validate_presence_of(:receiving_organisation_type) }

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
