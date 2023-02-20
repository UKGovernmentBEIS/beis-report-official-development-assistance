RSpec.describe CommitmentPresenter do
  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      commitment = Commitment.new(value: 100_000)
      expect(described_class.new(commitment).value).to eq("£100,000.00")
    end
  end

  describe "#transaction_date" do
    context "when the transaction date is set" do
      it "returns a human readable date" do
        commitment = build(:commitment, transaction_date: Date.parse("2023-02-20"))
        result = described_class.new(commitment).transaction_date
        expect(result).to eq("20 Feb 2023")
      end
    end

    context "if, for any reason, no transaction date is set" do
      it "returns an empty string" do
        commitment = build(:commitment, transaction_date: nil)
        result = described_class.new(commitment).transaction_date
        expect(result).to eq("")
      end
    end
  end
end
