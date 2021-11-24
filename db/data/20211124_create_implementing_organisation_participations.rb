# Run me with `rails runner db/data/20211124_create_implementing_organisation_participations.rb`

ImplementingOrganisation.where.not(name: "0").each do |org|
  next unless org.activity

  unique_org = Organisation.find_matching(org.name)
  if unique_org
    puts "#{org.name} maps to Unique IO named #{unique_org.name}"
    begin
      org.activity.unique_implementing_organisations << unique_org
    rescue ActiveRecord::RecordNotUnique => _error
      puts "  the 'Implementing' OrgParticipation already exists..."
    end
  else
    abort "There is no Unique Implementing Org matching #{org.name}"
  end
end
