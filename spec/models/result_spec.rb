RSpec.describe Result do
  describe "#success?" do
    it "returns true when set to true" do
      result = described_class.new(true).success?
      expect(result).to eq true
    end

    it "returns false when set to false" do
      result = described_class.new(false).success?
      expect(result).to eq false
    end
  end

  describe "#failure?" do
    it "returns true when set to false" do
      result = described_class.new(false).failure?
      expect(result).to eq true
    end

    it "returns false when set to true" do
      result = described_class.new(true).failure?
      expect(result).to eq false
    end
  end
end
