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

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Actual.ancestors).to include(Transaction)
      expect(Actual.table_name).to eq("transactions")
      expect(Actual.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Actual'" do
      expect(Actual.new.type).to eq("Actual")
    end

    it "should have the _transaction_type_ of '3' for 'Disbursement'" do
      expect(Actual.new.transaction_type).to eq("3")
    end

    it "should have the _currency_ of 'GBP'" do
      expect(Actual.new.currency).to eq("GBP")
    end
  end
end
