require "csv"

desc "Imports Commitments from a CSV file"
namespace :commitments do
  task import: :environment do
    path = ENV["CSV"]
    abort "You must specify a CSV (e.g. `bin/rails commitments:import CSV=path/to/file.csv`)" if path.nil?

    csv = CSV.read(path, {headers: true, encoding: "bom|utf-8"})

    importer = Import::Commitments.new

    if importer.call(csv)
      importer.imported.each do |commitment|
        puts "commitment id: #{commitment.id} | activity_id: #{commitment.activity_id} | value: #{commitment.value} "
      end
      puts "\n#{importer.imported.count} commitments imported successfully."
    else
      importer.errors.each do |error|
        puts "Row #{error.row_number}: #{error.message}"
      end
      puts "\nThere were errors, no commitments were imported."
    end
  rescue Errno::ENOENT
    abort "Cannot find the file at #{path}"
  end
end
