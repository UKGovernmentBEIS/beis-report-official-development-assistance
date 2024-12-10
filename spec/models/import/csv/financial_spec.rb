require "rails_helper"

RSpec.describe Import::Csv::Financial do
  describe "#value" do
    context "when the value is positive number" do
      it "returns a BigDecimal of the number" do
        csv_value = "1000.0"
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal("1_000")
      end
    end

    context "when the value is negative number" do
      it "returns a BigDecimal of the number" do
        csv_value = "-1000.0"
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal("-1_000")
      end
    end

    context "when the value is zero" do
      it "returns a BigDecimal of zero" do
        csv_value = "0.0"
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal(0)
      end
    end

    context "when the value has financial punctuation" do
      it "returns a BigDecimal of the number" do
        csv_value = "£1,000,000,000.0"
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal("1_000_000_000")
      end
    end

    context "when the value is space" do
      it "returns a BigDecimal of zero" do
        csv_value = " "
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal(0)
      end
    end

    context "when the value is multiple spaces" do
      it "returns a BigDecimal of zero" do
        csv_value = "   "
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal(0)
      end
    end

    context "when the value is nil" do
      it "returns a BigDecimal of zero" do
        csv_value = nil
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal(0)
      end
    end

    context "when the value is empty" do
      it "returns a BigDecimal of zero" do
        csv_value = ""
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to eql BigDecimal(0)
      end
    end

    context "when the value cannot be converted" do
      it "returns nil" do
        csv_value = "this cannot be converted"
        finance_value = described_class.new(csv_value)

        expect(finance_value.decimal_value).to be_nil
      end
    end
  end

  describe "#original_value" do
    context "when the conversion can take place" do
      it "returns the original string from the csv cell" do
        csv_value = "1000.0"
        finance_value = described_class.new(csv_value)

        expect(finance_value.original_value).to eql csv_value
      end
    end

    context "when the conversion cannot take place" do
      it "returns the original string from the csv cell" do
        csv_value = "ten thousand pounds"
        finance_value = described_class.new(csv_value)

        expect(finance_value.original_value).to eql csv_value
      end
    end
  end
end
