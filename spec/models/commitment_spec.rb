RSpec.describe Commitment do
  it { should belong_to(:activity) }

  describe ".value" do
    it "must be a number" do
      commitment = build(:commitment, value: "not a number")
      expect(commitment.valid?).to be false
    end

    it "cannot be zero" do
      commitment = build(:commitment, value: 0)
      expect(commitment.valid?).to be false
    end

    it "cannot be negative" do
      commitment = build(:commitment, value: -1000.00)
      expect(commitment.valid?).to be false
    end

    it "cannot exceed 99_999_999_999_00" do
      commitment = build(:commitment, value: 100_000_000_000_00)
      expect(commitment.valid?).to be false
    end

    it "can be a number within the allowed range" do
      commitment = build(:commitment, value: 100_000_00)
      expect(commitment.valid?).to be true
    end
  end
end
