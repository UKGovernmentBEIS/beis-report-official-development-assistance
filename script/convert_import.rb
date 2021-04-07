require "csv"
require "optparse"
require_relative "../config/environment"
require_relative "../app/services/import_converter"

BYTE_ORDER_MARK = "\uFEFF".encode(Encoding::UTF_8)

parser = OptionParser.new { |args|
  args.on "-i", "--input FILE"
  args.on "-o", "--output FILE"
  args.on "-l", "--level LEVEL"
}

options = {}
parser.parse!(into: options)

level = options.fetch(:level).upcase
input_data = File.read(options.fetch(:input))
input_data.delete_prefix!(BYTE_ORDER_MARK)
rows = CSV.parse(input_data, headers: true)

output = options.fetch(:output)
transaction_output = CSV.open("#{output}_transactions.csv", "w")
forecast_output = CSV.open("#{output}_forecasts.csv", "w")

first_row = ImportConverter.new(rows.first, level: level)
forecast_mappings = first_row.forecast_mappings

transaction_output << first_row.transaction_headers
forecast_output << first_row.forecast_headers

rows.each do |row|
  converter = ImportConverter.new(row, level: level, forecast_mappings: forecast_mappings)

  converter.transaction_tuples.each do |tuple|
    transaction_output << tuple
  end

  converter.forecast_tuples.each do |tuple|
    forecast_output << tuple
  end
end

transaction_output.close
forecast_output.close
