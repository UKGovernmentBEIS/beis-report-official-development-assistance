require "csv"

desc "Imports Activities from a CSV file"
namespace :activities do
  task import: :environment do
    path = ENV["CSV"]
    organisation_id = ENV["ORGANISATION_ID"]
    uploader_email = ENV["UPLOADER_EMAIL"]

    abort "You must specify a CSV (e.g. `rake activities:import CSV=path/to/file.csv ORGANISATION_ID=8c3b69ec-1e9c-49ae-8e04-7c5d3826b253 UPLOADER_EMAIL=email@example.com`)" if path.nil?
    abort "You must specify an organisation ID (e.g. `rake activities:import CSV=path/to/file.csv ORGANISATION_ID=8c3b69ec-1e9c-49ae-8e04-7c5d3826b253 UPLOADER_EMAIL=email@example.com`)" if organisation_id.nil?
    abort "You must specify an uploader email (e.g. `rake activities:import CSV=path/to/file.csv ORGANISATION_ID=8c3b69ec-1e9c-49ae-8e04-7c5d3826b253 UPLOADER_EMAIL=email@example.com`)" if uploader_email.nil?

    organisation = Organisation.find(organisation_id)
    uploader = User.find_by!(email: uploader_email)

    file = File.open(path, encoding: "bom|utf-8")
    csv = CSV.parse(file.read, headers: true)

    importer = Activities::ImportFromCsv.new(delivery_partner_organisation: organisation, uploader: uploader)
    importer.import(csv)

    if importer.errors.empty?
      puts "Successfully created #{pluralize(importer.created.count, "activity")} and updated #{pluralize(importer.updated.count, "activity")}"
    else
      # Output errors
      puts "There were #{pluralize(importer.errors.count, "error")} when importing"
      importer.errors.each do |error|
        puts "At row #{error.csv_row}, column `#{error.csv_column}`: #{error.message}"
      end
    end
  rescue Errno::ENOENT
    abort "Cannot find the file at #{path}"
  rescue ActiveRecord::RecordNotFound => error
    abort error.message
  end

  def pluralize(count, string)
    count.to_s + " " + string.pluralize(count)
  end
end
