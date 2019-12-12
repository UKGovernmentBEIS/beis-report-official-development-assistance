require "rails_helper"

RSpec.describe Transaction, type: :model do
  describe "relations" do
    it { should belong_to(:fund) }
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

  context "value must be between 1 and 99,999,999,999 (100 billion minus one)" do
    let(:fund) { build(:fund) }

    it "does allows the maximum possible value" do
      transaction = build(:transaction, fund: fund, value: 99_999_999_999.00)
      expect(transaction.valid?).to be_truthy
    end

    it "does not allow a value of less than 1" do
      transaction = build(:transaction, fund: fund, value: -1)
      expect(transaction.valid?).to be_falsey
    end

    it "does not allow a value of more than 99,999,999,999" do
      transaction = build(:transaction, fund: fund, value: 10_000_000_000)
      expect(transaction.valid?).to be_falsey
    end

    it "allows a value between 1 and 99,999,999,999" do
      transaction = build(:transaction, fund: fund, value: 500_000)
      expect(transaction.valid?).to be_truthy
    end
  end
end
