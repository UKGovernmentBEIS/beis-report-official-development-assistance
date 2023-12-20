module CsvImportHelpers
  def valid_csv_row(actual: "10000", refund: "0", comment: "This is a comment.")
    row = double(CSV::Row)
    allow(row).to receive(:field).with("Activity RODA Identifier").and_return("GCRF-UKSA-DJ94DSK0-ID")
    allow(row).to receive(:field).with("Financial Quarter").and_return("1")
    allow(row).to receive(:field).with("Financial Year").and_return("2023")
    allow(row).to receive(:field).with("Actual Value").and_return(actual)
    allow(row).to receive(:field).with("Refund Value").and_return(refund)
    allow(row).to receive(:field).with("Comment").and_return(comment)
    allow(row).to receive(:field).with("Receiving Organisation Name").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation IATI Reference").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation Type").and_return(nil)

    row
  end
end
