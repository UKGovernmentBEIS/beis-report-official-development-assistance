require "rails_helper"

RSpec.describe Import::Csv::ImportedRow do
  describe "#csv_row_number" do
    it "returns the row number of the imported item from the source file" do
      result = described_class.new(0, nil)

      expect(result.csv_row_number).to be 2
    end
  end

  describe "#object" do
    it "returns the object that the imported row result in" do
      imported_object = double("Imported Object")
      result = described_class.new(0, imported_object)

      expect(result.object).to be imported_object
    end
  end
end
