RSpec.describe Actual do
  describe "validations" do
    context "with no validation context" do
      it "allows positive values" do
        actual = build(:actual, value: 10_000)
        expect(actual.valid?).to be true
      end

      it "does not allow negative values" do
        actual = build(:actual, value: -10_000)
        expect(actual.valid?).to be false
      end
    end

    context "with the `:history` validation context" do
      it "allows positive values" do
        actual = build(:actual, value: 10_000)
        expect(actual.valid?(:history)).to be true
      end

      it "allows negative values" do
        actual = build(:actual, value: -10_000)
        expect(actual.valid?(:history)).to be true
      end
    end
  end
end
