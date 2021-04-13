# Run me with `rails runner db/data/20210412134546_fix_extending_organisation_inconsistencies.rb`

beis = Organisation.find_by(service_owner: true)

Activity.fund.update_all(organisation_id: beis.id, extending_organisation_id: beis.id)

Activity.programme.where.not(extending_organisation_id: beis.id).update_all(organisation_id: beis.id)

Activity.project.update_all("extending_organisation_id = organisation_id")

Activity.third_party_project.update_all("extending_organisation_id = organisation_id")

bad_programmes = Activity.programme.where(extending_organisation_id: beis.id)

if bad_programmes.any?
  puts "Found #{bad_programmes.size} programme(s) whose extending_organisation is incorrectly set to BEIS and should be manually corrected:"
  puts bad_programmes.ids.join("\n")
end
