# Run me with `rails runner db/data/20211116_seed_unique_implementing_organisations.rb`

if UniqueImplementingOrganisation.any?
  abort "We have already seeded the Unique Implementing Organisations"
end

require "csv"
path = "db/seeds/unique_implementing_orgs.csv"

CSV.readlines(path, encoding: "bom|utf-8", headers: true).each do |row|
  name = row["NAME"]
  legacy_names = row["LEGACY_NAMES"]
  organisation_type = row["ORG_TYPE"]
  iati_reference = row["IATI_REF"]

  puts "seeding: #{name} with legacy names: #{legacy_names}"

  UniqueImplementingOrganisation.create!(
    name: name,
    legacy_names: legacy_names,
    organisation_type: organisation_type,
    reference: iati_reference
  )
end

puts
puts "#{UniqueImplementingOrganisation.count} Unique Implementing Orgs created."
