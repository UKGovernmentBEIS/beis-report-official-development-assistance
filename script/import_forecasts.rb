require "optparse"
require_relative "../config/environment"

parser = OptionParser.new { |args|
  args.on "-f", "--fund FUND"
  args.on "-o", "--organisation ORGANISATION"
  args.on "-q", "--quarter QUARTER", Integer
  args.on "-y", "--year YEAR", Integer
  args.on "-i", "--input FILE"
}

options = {}
parser.parse!(into: options)

fund = Activity.fund.by_roda_identifier(options.fetch(:fund))
organisation = Organisation.find_by(name: options.fetch(:organisation))

unless fund
  warn "Could not find fund with RODA identifier '#{options.fetch(:fund)}'"
  exit 1
end

unless organisation
  warn "Could not find organisation with name '#{options.fetch(:organisation)}'"
  exit 1
end

def zero_option_to_nil(options, field)
  value = options.fetch(field)
  value == 0 ? nil : value
end

report = Report.find_by(
  fund: fund,
  organisation: organisation,
  financial_quarter: zero_option_to_nil(options, :quarter),
  financial_year: zero_option_to_nil(options, :year),
)

unless report
  warn "Could not find report with the given parameters"
  exit 1
end

puts "\nRunning import with the following report:\n\n"
puts "    id:           #{report.id}"
puts "    description:  #{report.description}"
puts "    fund:         #{report.fund.roda_identifier}"
puts "    organisation: #{report.organisation.name}"
puts "    quarter:      #{report.financial_quarter_and_year}"
puts "    state:        #{report.state}"

puts "\nIs this correct? [y/n]"
confirmation = gets
exit unless confirmation.strip == "y"

importer = ImportPlannedDisbursements.new(report: report)
rows = CSV.parse(File.read(options.fetch(:input)), headers: true)

importer.import(rows)

importer.errors.each do |error|
  warn "Line #{error.csv_row}, column '#{error.column}': #{error.message}"
end

if importer.errors.empty?
  exit 0
else
  exit 1
end
