# Run me with `rails runner db/data/20211123_add_uniq_implementing_orgs_to_orgs.rb`

require "csv"
path = "db/seeds/implementing_organisation_additions.csv"

implementing_orgs_to_migrate = <<~SQL
  SELECT implementing_organisations.name      AS io_name,
         organisations.name                   AS o_name
  FROM implementing_organisations
         LEFT OUTER JOIN organisations ON implementing_organisations.name = organisations.name
    OR (implementing_organisations.name = ANY (organisations.alternate_names))
  WHERE organisations.name IS NULL
    AND NOT implementing_organisations.name = '0'
  GROUP BY io_name, o_name
SQL

counter = -> { ImplementingOrganisation.find_by_sql(implementing_orgs_to_migrate) }

puts "\n\n---"
puts "There are #{counter.call.count} unique implementing orgs to migrate the _organisations_ table"
puts

CSV.readlines(path, encoding: "bom|utf-8", headers: true).each do |row|
  org_name = row["org_name"]
  new_org_name = row["name"]
  alternate_names = row["alternate_names"]
  organisation_type = row["org_type"]
  iati_reference = row["ref"]

  if org_name
    org = Organisation.find_by!(name: org_name)
    puts "#{org.name} ALREADY exists"
    if alternate_names.present?
      puts "  adding alternate_names: #{alternate_names}"
      org.update!(alternate_names: alternate_names)
    else
      puts "  no alternate names to add"
    end
  else
    print "#{new_org_name} will be created or updated"
    print " with alternate names #{alternate_names}" if alternate_names.present?
    new_org = Organisation.find_by(name: new_org_name) || Organisation.new(name: new_org_name)
    new_org.assign_attributes(
      alternate_names: alternate_names,
      organisation_type: organisation_type,
      iati_reference: iati_reference,
      active: true
    )
    new_org.save!(validate: false)
    puts
  end
end
puts "\n\n---"
puts "There are now #{counter.call.count} unique implementing orgs to migrate to the _organisations_ table"
puts "---"
