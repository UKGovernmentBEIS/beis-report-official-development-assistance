require "rails_helper"

RSpec.describe Import::RowError do
  subject {
    described_class.new(
      row_number: 10,
      column: "Column Header",
      value: "The value",
      message: "The message"
    )
  }

  describe "#row_number" do
    it "returns the supplied row_number" do
      expect(subject.row_number).to eql 10
    end
  end

  describe "#column" do
    it "returns the supplied column header" do
      expect(subject.column).to eql "Column Header"
    end
  end

  describe "#value" do
    it "returns the supplier value" do
      expect(subject.value).to eql "The value"
    end
  end

  describe "#csv_row_number" do
    it "returns the supplied row_number as it appears in the csv file" do
      expect(subject.csv_row_number).to eql 12
    end
  end

  describe "#csv_row" do
    it "returns csv_row_number to maintain compatibility with the existing importer" do
      expect(subject.csv_row).to eql subject.csv_row_number
    end
  end

  describe "#message" do
    it "returns the supplied message" do
      expect(subject.message).to eql "The message"
    end
  end
end
