require "csv"

# Run me with `rails runner db/data/20210301120758_populate_beis_organisation_reference_for_organisations.rb`

file = File.open("vendor/data/beis_organisation_references/beis_organisation_references.csv", encoding: "bom|utf-8")
org_data = CSV.parse(file.read, headers: true)

org_data.each do |org_row|
  organisation = Organisation.find_by(name: org_row["RODA name"].strip)
  next unless organisation

  organisation.beis_organisation_reference = org_row["RODA short version"].strip
  organisation.save!
end
