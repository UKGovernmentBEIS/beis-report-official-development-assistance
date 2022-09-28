require "csv"

desc "Imports Commitments from a CSV file"
namespace :commitments do
  task import: :environment do
    path = ENV["CSV"]
    user_email = ENV["USER_EMAIL"]

    user = User.find_by(email: user_email)

    abort "You must specify a CSV (e.g. `bin/rails commitments:import CSV=path/to/file.csv`)" if path.nil?
    abort "You must specify a USER_EMAIL (e.g. `bin/rails commitments:import USER_EMAIL=somone@here.com`)" if user_email.nil?
    abort "Unknown user email address" if user.nil?

    csv = CSV.read(path, {headers: true, encoding: "bom|utf-8"})

    importer = Commitment::Import.new(user)

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
