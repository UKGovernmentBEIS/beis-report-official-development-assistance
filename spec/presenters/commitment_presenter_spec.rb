RSpec.describe CommitmentPresenter do
  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      commitment = Commitment.new(value: 100_000)
      expect(described_class.new(commitment).value).to eq("£100,000.00")
    end
  end
end
