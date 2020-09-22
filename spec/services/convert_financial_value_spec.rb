require "rails_helper"

RSpec.describe ConvertFinancialValue do
  let(:converter) { ConvertFinancialValue.new }

  it "converts zero" do
    expect(converter.convert("0")).to eq(BigDecimal("0"))
  end

  it "converts an integer" do
    expect(converter.convert("42")).to eq(BigDecimal("42"))
  end

  it "converts a fractional value" do
    expect(converter.convert("5.02")).to eq(BigDecimal("5.02"))
  end

  it "converts a negative value" do
    expect(converter.convert("- 3")).to eq(BigDecimal("-3"))
  end

  it "converts a number with a leading £ sign" do
    expect(converter.convert("£ 10")).to eq(BigDecimal("10"))
  end

  it "converts a number containing commas" do
    expect(converter.convert("1,234,567")).to eq(BigDecimal("1234567"))
  end

  it "converts a number with surrounding spaces" do
    expect(converter.convert(" 9 ")).to eq(BigDecimal("9"))
  end

  it "converts a number with all supported features" do
    expect(converter.convert(" £  - 12,345.67 ")).to eq(BigDecimal("-12345.67"))
  end

  it "rejects a number containing a letter" do
    expect { converter.convert("1a2") }.to raise_error(ConvertFinancialValue::Error)
  end
end
