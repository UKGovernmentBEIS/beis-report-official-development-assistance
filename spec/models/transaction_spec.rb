require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:fund) { build(:fund) }

  describe "relations" do
    it { should belong_to(:hierarchy) }
  end

  describe "validations" do
    it { should validate_presence_of(:reference) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:disbursement_channel) }
  end

  context "value must be between 1 and 99,999,999,999.00 (100 billion minus one)" do
    let(:fund) { build(:fund) }

    it "allows the maximum possible value" do
      transaction = build(:transaction, hierarchy: fund, value: 99_999_999_999.00)
      expect(transaction).to be_valid
    end

    it "does not allow a value of less than 1" do
      transaction = build(:transaction, hierarchy: fund, value: -1)
      expect(transaction).to_not be_valid
    end

    it "does not allow a value of more than 99,999,999,999.00" do
      transaction = build(:transaction, hierarchy: fund, value: 100_000_000_000.00)
      expect(transaction).to_not be_valid
    end

    it "allows a value between 1 and 99,999,999,999.00" do
      transaction = build(:transaction, hierarchy: fund, value: 500_000.00)
      expect(transaction).to be_valid
    end
  end

  context "date must be between 10 years ago and 25 years from now" do
    it "does not allow a date more than 10 years ago" do
      transaction = build(:transaction, hierarchy: fund, date: 11.years.ago)
      expect(transaction).to_not be_valid
      expect(transaction.errors[:date]).to include "Date must be between 10 years ago and 25 years in the future"
    end

    it "does not allow a date more than 25 years in the future" do
      transaction = build(:transaction, hierarchy: fund, date: 26.years.from_now)
      expect(transaction).to_not be_valid
      expect(transaction.errors[:date]).to include "Date must be between 10 years ago and 25 years in the future"
    end

    it "allows a date between 10 years ago and 25 years in the future" do
      transaction = build(:transaction, hierarchy: fund, date: Date.today)
      expect(transaction).to be_valid
    end

    it "allows a nil date" do
      transaction = build(:transaction, hierarchy: fund, date: Date.today)
      expect(transaction).to be_valid
    end
  end
end
