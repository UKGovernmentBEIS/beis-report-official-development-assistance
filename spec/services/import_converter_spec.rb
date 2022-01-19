RSpec.describe ImportConverter do
  let(:activity_level) { "C" }
  let(:forecast_mappings) { nil }

  let :converter do
    ImportConverter.new(input_row, level: activity_level, forecast_mappings: forecast_mappings)
  end

  describe "transaction data" do
    let :input_row do
      {
        "Parent RODA ID" => "AAA-BBB ",
        "RODA ID Fragment" => " CCC",
        "Act 2020/21 Q1" => "90",
        "Act 2020/21 FY Q2 (Jul, Aug, Sep)" => "70",
        "Q3 2020-2021 actuals" => "50",
        "Act 2020/21 Q4" => "0",
        "Q3 2020-2021 forecast" => "40"
      }
    end

    it "returns the transaction importer column headers" do
      expect(converter.transaction_headers).to eq([
        "Activity RODA Identifier",
        "Financial Year",
        "Financial Quarter",
        "Value"
      ])
    end

    it "recognises all transaction headers" do
      expect(converter.transaction_tuples).to eq([
        ["AAA-BBB-CCC", "2020", "1", "90"],
        ["AAA-BBB-CCC", "2020", "2", "70"],
        ["AAA-BBB-CCC", "2020", "3", "50"]
      ])
    end

    context "for level D activities" do
      let(:activity_level) { "D" }

      it "does not insert '-' between the ID fragments" do
        expect(converter.transaction_tuples).to eq([
          ["AAA-BBBCCC", "2020", "1", "90"],
          ["AAA-BBBCCC", "2020", "2", "70"],
          ["AAA-BBBCCC", "2020", "3", "50"]
        ])
      end
    end
  end

  describe "forecast data" do
    let :input_row do
      {
        "Parent RODA ID" => "AAA-BBB",
        "RODA ID Fragment" => "CCC",
        "FC Q1 2020-21" => "90",
        "FC Q2 2020" => "80",
        "Q3 2020-2021 forecast" => "70",
        "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "60",
        "Q3 2020-2021 actuals" => "50"
      }
    end

    it "returns the forecast importer column headers" do
      expect(converter.forecast_headers).to eq([
        "Activity RODA Identifier",
        "FC 2020/21 FY Q1",
        "FC 2020/21 FY Q2",
        "FC 2020/21 FY Q3",
        "FC 2020/21 FY Q4"
      ])
    end

    it "recognises all forecast headers" do
      expect(converter.forecast_tuples).to eq([
        ["AAA-BBB-CCC", "90", "80", "70", "60"]
      ])
    end

    it "returns forecast column mappings" do
      expect(converter.forecast_mappings).to eq([
        ["FC 2020/21 FY Q1", "FC Q1 2020-21"],
        ["FC 2020/21 FY Q2", "FC Q2 2020"],
        ["FC 2020/21 FY Q3", "Q3 2020-2021 forecast"],
        ["FC 2020/21 FY Q4", "FC 2020/21 FY Q4 (Jan, Feb, Mar)"]
      ])
    end

    context "when given forecast mappings explicitly" do
      let :forecast_mappings do
        [
          ["FC 2020/21 FY Q3", "Q3 2020-2021 forecast"],
          ["FC 2020/21 FY Q2", "FC Q2 2020"],
          ["FC 2020/21 FY Q4", "FC 2020/21 FY Q4 (Jan, Feb, Mar)"]
        ]
      end

      it "returns forecast values in the matching order" do
        expect(converter.forecast_tuples).to eq([
          ["AAA-BBB-CCC", "70", "80", "60"]
        ])
      end
    end
  end
end
