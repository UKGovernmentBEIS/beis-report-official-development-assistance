RSpec.shared_examples "a financial value in a csv row" do |header|
  context "when the value is zero" do
    it "is valid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return("0")
      row = described_class.new(csv_row)

      expect(row).to be_valid
    end
  end

  context "when the value is a positive number" do
    it "is valid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return("1000.00")
      row = described_class.new(csv_row)

      expect(row).to be_valid
    end
  end

  context "when the value is empty" do
    it "is valid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return(nil)
      row = described_class.new(csv_row)

      expect(row.valid?).to be true
    end
  end

  context "when the value is a negative number" do
    it "is valid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return("-1000.00")
      row = described_class.new(csv_row)

      expect(row.valid?).to be true
    end
  end

  context "when the value has pence" do
    it "is valid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return("1000.86")
      row = described_class.new(csv_row)

      expect(row).to be_valid
    end
  end

  context "when the value is not numeric" do
    it "is invalid" do
      csv_row = valid_csv_row
      allow(csv_row).to receive(:field).and_call_original
      allow(csv_row).to receive(:field).with(header).and_return("This is not a number")
      row = described_class.new(csv_row)

      expect(row).to be_invalid
      expect(row.errors.count).to be 1

      error_message = row.errors[header][1]

      expect(error_message).to include("must be blank or numeric")
    end
  end
end
